// Black Belt Ethical Auditor - Linux C++17 CLI.
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

static void usage(const char* p) {
    std::cout << "Usage: " << p << " [--file FILE] [--version] [--help]\n"
              << "       " << p << " < audit.json\n\n"
              << "Black Belt Ethical Auditor Linux CLI (C++17).\n"
              << "Interactive mode accepts questions or JSON audit objects.\n";
}

static std::string shellQuote(const std::string& s) {
    std::string r = "'";
    for (char c : s) r += (c == '\'' ? "'\\''" : std::string(1, c));
    return r + "'";
}

static std::string engineCommand() {
    const char* env = std::getenv("BBEA_ENGINE_CMD");
    if (env && *env) return env;
    char exe[4096];
    ssize_t n = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
    if (n > 0) {
        exe[n] = '\0';
        std::string path(exe);
        auto slash = path.find_last_of('/');
        if (slash != std::string::npos) return path.substr(0, slash + 1) + "blackbelt-engine.sh";
    }
    return "bin/blackbelt-engine.sh";
}

static int runEngine(const std::string& input) {
    char tmp[] = "/tmp/blackbelt-cpp-XXXXXX";
    int fd = mkstemp(tmp);
    if (fd < 0) { perror("mkstemp"); return 2; }
    FILE* fp = fdopen(fd, "wb");
    if (!fp) { perror("fdopen"); close(fd); unlink(tmp); return 2; }
    if (fwrite(input.data(), 1, input.size(), fp) != input.size() || fputc('\n', fp) == EOF) {
        perror("write"); fclose(fp); unlink(tmp); return 2;
    }
    fclose(fp);
    std::string command = "cat " + shellQuote(tmp) + " | " + shellQuote(engineCommand());
    int status = std::system(command.c_str());
    unlink(tmp);
    if (status == -1) return 3;
    return WIFEXITED(status) ? WEXITSTATUS(status) : 3;
}

static int interactive() {
    std::cout << "Black Belt Ethical Auditor\n"
              << "Ask a question or enter a JSON audit object. Type 'help' or 'quit'.\n";
    std::string line;
    for (;;) {
        std::cout << "black-belt> " << std::flush;
        if (!std::getline(std::cin, line)) break;
        if (line.empty()) continue;
        if (line == "quit" || line == "exit") break;
        if (line == "help") {
            std::cout << "Enter a natural-language question or a complete BBEA JSON audit object.\n"
                      << "Commands: help, quit, exit\n";
            continue;
        }
        int rc = runEngine(line);
        if (rc != 0) std::cerr << "Audit failed (exit " << rc << ").\n";
    }
    std::cout << '\n';
    return 0;
}

int main(int argc, char** argv) {
    std::string file;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--help" || a == "-h") { usage(argv[0]); return 0; }
        if (a == "--version") { std::cout << "blackbelt-cpp 1.2 (BBEA CLI v2 transport)\n"; return 0; }
        if (a == "--file" && i + 1 < argc) { file = argv[++i]; continue; }
        std::cerr << "Unknown argument: " << a << '\n'; usage(argv[0]); return 2;
    }
    if (file.empty() && isatty(STDIN_FILENO)) return interactive();
    std::string input;
    if (file.empty()) input.assign(std::istreambuf_iterator<char>(std::cin), std::istreambuf_iterator<char>());
    else {
        std::ifstream in(file, std::ios::binary);
        if (!in) { std::cerr << "Unable to open " << file << '\n'; return 2; }
        input.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    }
    if (input.find_first_not_of(" \t\r\n") == std::string::npos) {
        std::cerr << "No audit input received.\n"; return 2;
    }
    return runEngine(input);
}
