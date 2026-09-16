// Black Belt Ethical Auditor - Linux C++17 CLI.
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <sys/wait.h>
#include <unistd.h>
#include <ctime>
#include <filesystem>

static void usage(const char* p) {
    std::cout << "Usage: " << p << " [--file FILE] [--save FILE] [--no-save] [--version] [--help]\n"
              << "       " << p << " < audit.json\n\n"
              << "Black Belt Ethical Auditor Linux CLI (C++17).\n"
              << "Interactive mode accepts questions or JSON audit objects.\n"
              << "Responses are saved exactly as received by default.\n"
              << "Environment: BBEA_ENGINE_CMD, BBEA_ENGINE_URL, BBEA_MODEL, BBEA_SYSTEM_PROMPT, BBEA_SAVE_DIR, BBEA_TRANSPORT.\n";
}

static std::string shellQuote(const std::string& s) {
    std::string r = "'";
    for (char c : s) r += (c == '\'' ? "'\\''" : std::string(1, c));
    return r + "'";
}

static std::string engineCommand() {
    const char* env = std::getenv("BBEA_ENGINE_CMD"); if (env && *env) return env;
    char exe[4096]; ssize_t n = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
    if (n > 0) { exe[n] = '\0'; std::string path(exe); auto slash = path.find_last_of('/'); if (slash != std::string::npos) return path.substr(0, slash + 1) + "blackbelt-engine.sh"; }
    return "modules/black-belt/bin/blackbelt-engine.sh";
}

static std::string outputHelper() {
    char exe[4096]; ssize_t n = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
    if (n > 0) { exe[n] = '\0'; std::string path(exe); auto slash = path.find_last_of('/'); if (slash != std::string::npos) return path.substr(0, slash + 1) + "blackbelt-output.sh"; }
    return "modules/black-belt/bin/blackbelt-output.sh";
}

static bool copyExact(const std::string& src, const std::string& dst) {
    std::ifstream in(src, std::ios::binary);
    std::ofstream out(dst, std::ios::binary);
    if (!in || !out) return false;
    out << in.rdbuf();
    return static_cast<bool>(out);
}

static std::string defaultSavePath() {
    const char* configured = std::getenv("BBEA_SAVE_DIR");
    std::string dir = configured && *configured ? configured : (std::getenv("HOME") ? std::string(std::getenv("HOME")) + "/.local/state/blackbelt/responses" : ".blackbelt-responses");
    std::filesystem::create_directories(dir);
    std::time_t now = std::time(nullptr); std::tm tmv{}; localtime_r(&now, &tmv);
    return dir + "/blackbelt-" + std::to_string(tmv.tm_year + 1900) +
           (tmv.tm_mon + 1 < 10 ? "0" : "") + std::to_string(tmv.tm_mon + 1) +
           (tmv.tm_mday < 10 ? "0" : "") + std::to_string(tmv.tm_mday) + "-" +
           (tmv.tm_hour < 10 ? "0" : "") + std::to_string(tmv.tm_hour) +
           (tmv.tm_min < 10 ? "0" : "") + std::to_string(tmv.tm_min) +
           (tmv.tm_sec < 10 ? "0" : "") + std::to_string(tmv.tm_sec) + "-" + std::to_string(getpid()) + ".json";
}

static int saveAndTransport(const std::string& responsePath, const std::string& requestedPath) {
    const char* noSave = std::getenv("BBEA_NO_SAVE");
    bool disabled = noSave && std::string(noSave) == "1";
    std::string saved = requestedPath;
    if (!disabled || !requestedPath.empty()) {
        if (saved.empty()) saved = defaultSavePath();
        if (!copyExact(responsePath, saved)) { std::cerr << "Unable to save exact response: " << saved << '\n'; return 4; }
        if (requestedPath.empty()) std::cerr << "[Black Belt] saved exact response: " << saved << '\n';
    }
    const char* transport = std::getenv("BBEA_TRANSPORT");
    if (transport && *transport) {
        std::string path = saved.empty() ? responsePath : saved;
        std::string command = "bash " + shellQuote(outputHelper()) + " " + shellQuote(path);
        if (std::system(command.c_str()) != 0) return 6;
    }
    return 0;
}

static int runEngine(const std::string& input, const std::string& savePath) {
    char inTmp[] = "/tmp/blackbelt-cpp-in-XXXXXX", outTmp[] = "/tmp/blackbelt-cpp-out-XXXXXX";
    int fd = mkstemp(inTmp); if (fd < 0) { perror("mkstemp"); return 2; }
    FILE* fp = fdopen(fd, "wb"); if (!fp) { perror("fdopen"); close(fd); unlink(inTmp); return 2; }
    if (fwrite(input.data(), 1, input.size(), fp) != input.size() || fputc('\n', fp) == EOF) { perror("write"); fclose(fp); unlink(inTmp); return 2; }
    fclose(fp);
    int ofd = mkstemp(outTmp); if (ofd < 0) { perror("mkstemp"); unlink(inTmp); return 2; } close(ofd);
    std::string command = "cat " + shellQuote(inTmp) + " | bash " + shellQuote(engineCommand()) + " > " + shellQuote(outTmp);
    int status = std::system(command.c_str()); unlink(inTmp);
    if (status == -1) { unlink(outTmp); return 3; }
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) { int rc = WIFEXITED(status) ? WEXITSTATUS(status) : 3; unlink(outTmp); return rc; }
    std::ifstream response(outTmp, std::ios::binary); if (!response) { unlink(outTmp); return 4; }
    std::cout << response.rdbuf(); std::cout.flush(); response.close();
    int rc = saveAndTransport(outTmp, savePath); unlink(outTmp); return rc;
}

static int interactive() {
    std::cout << "Black Belt Ethical Auditor\nAsk a question or enter a JSON audit object. Type 'help' or 'quit'.\n";
    std::string line;
    for (;;) {
        std::cout << "black-belt> " << std::flush;
        if (!std::getline(std::cin, line)) break;
        if (line.empty()) continue;
        if (line == "quit" || line == "exit") break;
        if (line == "help") { std::cout << "Enter a natural-language question or a complete BBEA JSON audit object.\nCommands: help, quit, exit\n"; continue; }
        int rc = runEngine(line, ""); if (rc != 0) std::cerr << "Audit failed (exit " << rc << ").\n";
    }
    std::cout << '\n'; return 0;
}

int main(int argc, char** argv) {
    std::string file, savePath; bool noSave = false;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--help" || a == "-h") { usage(argv[0]); return 0; }
        if (a == "--version") { std::cout << "blackbelt-cpp 1.3 (BBEA output/transport)\n"; return 0; }
        if (a == "--file" && i + 1 < argc) { file = argv[++i]; continue; }
        if (a == "--save" && i + 1 < argc) { savePath = argv[++i]; continue; }
        if (a == "--no-save") { noSave = true; continue; }
        std::cerr << "Unknown argument: " << a << '\n'; usage(argv[0]); return 2;
    }
    if (noSave) setenv("BBEA_NO_SAVE", "1", 1);
    if (file.empty() && isatty(STDIN_FILENO)) return interactive();
    std::string input;
    if (file.empty()) input.assign(std::istreambuf_iterator<char>(std::cin), std::istreambuf_iterator<char>());
    else { std::ifstream in(file, std::ios::binary); if (!in) { std::cerr << "Unable to open " << file << '\n'; return 2; } input.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()); }
    if (input.find_first_not_of(" \t\r\n") == std::string::npos) { std::cerr << "No audit input received.\n"; return 2; }
    return runEngine(input, savePath);
}
