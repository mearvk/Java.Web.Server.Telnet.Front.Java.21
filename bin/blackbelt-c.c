/* Black Belt Ethical Auditor - Linux C CLI
 * Reads canonical BBEA JSON from --file, stdin, or the interactive prompt
 * and sends it to the shared Black Belt engine transport. The AI engine remains external.
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

static void usage(const char *p) {
    printf("Usage: %s [--file FILE] [--version] [--help]\n", p);
    printf("       %s < audit.json\n\n", p);
    printf("Black Belt Ethical Auditor Linux CLI (C).\n");
    printf("Environment: BBEA_ENGINE_URL, BBEA_MODEL, BBEA_SYSTEM_PROMPT.\n");
}

static int run_engine(const char *input) {
    char tmp[] = "/tmp/blackbelt-c-XXXXXX";
    int fd = mkstemp(tmp);
    if (fd < 0) { perror("mkstemp"); return 2; }

    FILE *out = fdopen(fd, "wb");
    if (!out) {
        perror("fdopen");
        close(fd);
        unlink(tmp);
        return 2;
    }

    size_t length = strlen(input);
    if (fwrite(input, 1, length, out) != length || fputc('\n', out) == EOF) {
        perror("write");
        fclose(out);
        unlink(tmp);
        return 2;
    }
    fclose(out);

    const char *engine = getenv("BBEA_ENGINE_CMD");
    if (!engine || !*engine) engine = "bin/blackbelt-engine.sh";

    char command[4096];
    int written = snprintf(command, sizeof(command), "cat '%s' | '%s'", tmp, engine);
    if (written < 0 || (size_t)written >= sizeof(command)) {
        fprintf(stderr, "Engine command is too long.\n");
        unlink(tmp);
        return 3;
    }

    int status = system(command);
    unlink(tmp);
    if (status == -1) return 3;
    return WIFEXITED(status) ? WEXITSTATUS(status) : 3;
}

static int interactive(void) {
    char *line = NULL;
    size_t capacity = 0;

    puts("Black Belt Ethical Auditor");
    puts("Enter a JSON audit object, or type 'help' or 'quit'.");

    for (;;) {
        fputs("black-belt> ", stdout);
        fflush(stdout);
        ssize_t length = getline(&line, &capacity, stdin);
        if (length < 0) break;
        while (length > 0 && (line[length - 1] == '\n' || line[length - 1] == '\r'))
            line[--length] = '\0';
        if (length == 0) continue;
        if (!strcmp(line, "quit") || !strcmp(line, "exit")) break;
        if (!strcmp(line, "help")) {
            puts("Paste a complete BBEA JSON audit object at the prompt.");
            puts("Commands: help, quit, exit");
            continue;
        }
        int rc = run_engine(line);
        if (rc != 0) fprintf(stderr, "Audit failed (exit %d).\n", rc);
    }
    free(line);
    putchar('\n');
    return 0;
}

int main(int argc, char **argv) {
    const char *file = NULL;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            usage(argv[0]); return 0;
        }
        if (!strcmp(argv[i], "--version")) {
            puts("blackbelt-c 1.1 (BBEA CLI v2 transport)"); return 0;
        }
        if (!strcmp(argv[i], "--file") && i + 1 < argc) {
            file = argv[++i]; continue;
        }
        fprintf(stderr, "Unknown argument: %s\n", argv[i]);
        usage(argv[0]); return 2;
    }

    if (!file && isatty(STDIN_FILENO)) return interactive();

    FILE *in = stdin;
    if (file) {
        in = fopen(file, "rb");
        if (!in) { perror(file); return 2; }
    }

    char *input = NULL;
    size_t capacity = 0;
    ssize_t length = getdelim(&input, &capacity, '\0', in);
    if (file) fclose(in);
    if (length < 0 || !input || length == 0) {
        free(input);
        fprintf(stderr, "No JSON audit input received.\n");
        return 2;
    }

    int rc = run_engine(input);
    free(input);
    return rc;
}
