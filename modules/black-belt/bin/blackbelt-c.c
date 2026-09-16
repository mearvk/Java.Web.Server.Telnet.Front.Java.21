/* Black Belt Ethical Auditor - Linux C CLI. */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <time.h>

static void usage(const char *p) {
    printf("Usage: %s [--file FILE] [--save FILE] [--no-save] [--version] [--help]\n", p);
    printf("       %s < audit.json\n\n", p);
    printf("Black Belt Ethical Auditor Linux CLI (C).\n");
    printf("Interactive mode accepts questions or JSON audit objects.\n");
    printf("Responses are saved exactly as received by default.\n");
    printf("Environment: BBEA_ENGINE_CMD, BBEA_ENGINE_URL, BBEA_MODEL, BBEA_SYSTEM_PROMPT, BBEA_SAVE_DIR, BBEA_TRANSPORT.\n");
}

static const char *engine_command(char *buffer, size_t size) {
    const char *configured = getenv("BBEA_ENGINE_CMD");
    if (configured && *configured) return configured;
    ssize_t n = readlink("/proc/self/exe", buffer, size - 1);
    if (n > 0) {
        buffer[n] = '\0';
        char *slash = strrchr(buffer, '/');
        if (slash) {
            snprintf(slash + 1, size - (size_t)(slash + 1 - buffer), "blackbelt-engine.sh");
            return buffer;
        }
    }
    return "modules/black-belt/bin/blackbelt-engine.sh";
}

static const char *output_helper(char *buffer, size_t size) {
    ssize_t n = readlink("/proc/self/exe", buffer, size - 1);
    if (n > 0) {
        buffer[n] = '\0';
        char *slash = strrchr(buffer, '/');
        if (slash) {
            snprintf(slash + 1, size - (size_t)(slash + 1 - buffer), "blackbelt-output.sh");
            return buffer;
        }
    }
    return "modules/black-belt/bin/blackbelt-output.sh";
}

static void shell_quote(const char *src, char *dst, size_t size) {
    size_t used = 0;
    if (size) dst[used++] = '\'';
    for (; *src && used + 5 < size; ++src) {
        if (*src == '\'') {
            dst[used++] = '\''; dst[used++] = '\\'; dst[used++] = '\''; dst[used++] = '\'';
        } else dst[used++] = *src;
    }
    if (used + 2 <= size) { dst[used++] = '\''; dst[used] = '\0'; }
}

static int save_and_transport(const char *response_path, const char *requested_path) {
    if (getenv("BBEA_NO_SAVE") && !strcmp(getenv("BBEA_NO_SAVE"), "1") && !requested_path) return 0;

    char helper[4096], quoted[8192], command[24576];
    const char *helper_path = output_helper(helper, sizeof(helper));
    shell_quote(helper_path, quoted, sizeof(quoted));

    if (requested_path) {
        FILE *src = fopen(response_path, "rb");
        FILE *dst = fopen(requested_path, "wb");
        if (!src || !dst) { perror("save"); if (src) fclose(src); if (dst) fclose(dst); return 4; }
        char buf[65536]; size_t n;
        while ((n = fread(buf, 1, sizeof(buf), src)) > 0) if (fwrite(buf, 1, n, dst) != n) { perror("save"); fclose(src); fclose(dst); return 4; }
        fclose(src); fclose(dst);
    }

    if (!requested_path && !(getenv("BBEA_NO_SAVE") && !strcmp(getenv("BBEA_NO_SAVE"), "1"))) {
        const char *dir = getenv("BBEA_SAVE_DIR");
        if (!dir || !*dir) {
            const char *home = getenv("HOME");
            static char default_dir[4096];
            snprintf(default_dir, sizeof(default_dir), "%s/.local/state/blackbelt/responses", home ? home : ".");
            dir = default_dir;
        }
        char mkdir_cmd[8192]; shell_quote(dir, mkdir_cmd, sizeof(mkdir_cmd));
        snprintf(command, sizeof(command), "mkdir -p %s", mkdir_cmd);
        if (system(command) != 0) return 5;
        char filename[8192]; time_t now = time(NULL); struct tm tmv;
        localtime_r(&now, &tmv);
        snprintf(filename, sizeof(filename), "%s/blackbelt-%04d%02d%02d-%02d%02d%02d-%ld.json", dir,
                 tmv.tm_year + 1900, tmv.tm_mon + 1, tmv.tm_mday, tmv.tm_hour, tmv.tm_min, tmv.tm_sec, (long)getpid());
        FILE *src = fopen(response_path, "rb"); FILE *dst = fopen(filename, "wb");
        if (!src || !dst) { perror("response save"); if (src) fclose(src); if (dst) fclose(dst); return 5; }
        char buf[65536]; size_t n;
        while ((n = fread(buf, 1, sizeof(buf), src)) > 0) if (fwrite(buf, 1, n, dst) != n) { perror("response save"); fclose(src); fclose(dst); return 5; }
        fclose(src); fclose(dst);
        fprintf(stderr, "[Black Belt] saved exact response: %s\n", filename);
        requested_path = filename;
    }

    if (getenv("BBEA_TRANSPORT") && *getenv("BBEA_TRANSPORT")) {
        const char *transport_path = requested_path ? requested_path : response_path;
        char qpath[8192];
        shell_quote(transport_path, qpath, sizeof(qpath));
        int written = snprintf(command, sizeof(command), "bash %s %s", quoted, qpath);
        if (written < 0 || (size_t)written >= sizeof(command)) {
            fprintf(stderr, "Transport command is too long.\n");
            return 6;
        }
        if (system(command) != 0) return 6;
    }
    return 0;
}

static int run_engine(const char *input, const char *save_path) {
    char in_tmp[] = "/tmp/blackbelt-c-in-XXXXXX";
    char out_tmp[] = "/tmp/blackbelt-c-out-XXXXXX";
    int fd = mkstemp(in_tmp); if (fd < 0) { perror("mkstemp"); return 2; }
    FILE *out = fdopen(fd, "wb");
    if (!out) { perror("fdopen"); close(fd); unlink(in_tmp); return 2; }
    if (fwrite(input, 1, strlen(input), out) != strlen(input) || fputc('\n', out) == EOF) { perror("write"); fclose(out); unlink(in_tmp); return 2; }
    fclose(out);
    int ofd = mkstemp(out_tmp); if (ofd < 0) { perror("mkstemp"); unlink(in_tmp); return 2; }
    close(ofd);

    char engine_path[4096], qin[8192], qengine[8192], qout[8192], command[24576];
    shell_quote(in_tmp, qin, sizeof(qin)); shell_quote(engine_command(engine_path, sizeof(engine_path)), qengine, sizeof(qengine)); shell_quote(out_tmp, qout, sizeof(qout));
    int written = snprintf(command, sizeof(command), "cat %s | bash %s > %s", qin, qengine, qout);
    if (written < 0 || (size_t)written >= sizeof(command)) { fprintf(stderr, "Engine command is too long.\n"); unlink(in_tmp); unlink(out_tmp); return 3; }
    int status = system(command);
    unlink(in_tmp);
    if (status == -1) { unlink(out_tmp); return 3; }
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) { int rc = WIFEXITED(status) ? WEXITSTATUS(status) : 3; unlink(out_tmp); return rc; }

    FILE *response = fopen(out_tmp, "rb");
    if (!response) { perror("response"); unlink(out_tmp); return 4; }
    char buf[65536]; size_t n;
    while ((n = fread(buf, 1, sizeof(buf), response)) > 0) fwrite(buf, 1, n, stdout);
    fclose(response); fflush(stdout);

    int rc = save_and_transport(out_tmp, save_path);
    unlink(out_tmp);
    return rc;
}

static int interactive(void) {
    char *line = NULL; size_t capacity = 0;
    puts("Black Belt Ethical Auditor"); puts("Ask a question or enter a JSON audit object. Type 'help' or 'quit'.");
    for (;;) {
        fputs("black-belt> ", stdout); fflush(stdout);
        ssize_t length = getline(&line, &capacity, stdin); if (length < 0) break;
        while (length > 0 && (line[length - 1] == '\n' || line[length - 1] == '\r')) line[--length] = '\0';
        if (length == 0) continue;
        if (!strcmp(line, "quit") || !strcmp(line, "exit")) break;
        if (!strcmp(line, "help")) { puts("Enter a natural-language question or a complete BBEA JSON audit object."); puts("Commands: help, quit, exit"); continue; }
        int rc = run_engine(line, NULL); if (rc != 0) fprintf(stderr, "Audit failed (exit %d).\n", rc);
    }
    free(line); putchar('\n'); return 0;
}

int main(int argc, char **argv) {
    const char *file = NULL, *save_path = NULL; int no_save = 0;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { usage(argv[0]); return 0; }
        if (!strcmp(argv[i], "--version")) { puts("blackbelt-c 1.3 (BBEA output/transport)"); return 0; }
        if (!strcmp(argv[i], "--file") && i + 1 < argc) { file = argv[++i]; continue; }
        if (!strcmp(argv[i], "--save") && i + 1 < argc) { save_path = argv[++i]; continue; }
        if (!strcmp(argv[i], "--no-save")) { no_save = 1; continue; }
        fprintf(stderr, "Unknown argument: %s\n", argv[i]); usage(argv[0]); return 2;
    }
    if (no_save) setenv("BBEA_NO_SAVE", "1", 1);
    if (!file && isatty(STDIN_FILENO)) return interactive();
    FILE *in = stdin; if (file) { in = fopen(file, "rb"); if (!in) { perror(file); return 2; } }
    char *input = NULL; size_t capacity = 0; ssize_t length = getdelim(&input, &capacity, '\0', in); if (file) fclose(in);
    if (length < 0 || !input || length == 0) { free(input); fprintf(stderr, "No audit input received.\n"); return 2; }
    int rc = run_engine(input, save_path); free(input); return rc;
}
