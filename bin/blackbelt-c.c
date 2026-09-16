/* Black Belt Ethical Auditor - Linux C CLI
 * Reads canonical BBEA JSON from --file or stdin and sends it to the
 * shared Black Belt engine transport. The AI engine remains external.
 */
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

static int copy_stream(FILE *in) {
    int c;
    while ((c = fgetc(in)) != EOF) {
        if (fputc(c, stdout) == EOF) return 1;
    }
    return ferror(in) ? 1 : 0;
}

int main(int argc, char **argv) {
    const char *file = NULL;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            usage(argv[0]); return 0;
        }
        if (!strcmp(argv[i], "--version")) {
            puts("blackbelt-c 1.0 (BBEA CLI v2 transport)"); return 0;
        }
        if (!strcmp(argv[i], "--file") && i + 1 < argc) {
            file = argv[++i]; continue;
        }
        fprintf(stderr, "Unknown argument: %s\n", argv[i]);
        usage(argv[0]); return 2;
    }

    /* Materialize input to a pipe so the shared engine receives exactly one JSON document. */
    FILE *in = stdin;
    if (file) {
        in = fopen(file, "rb");
        if (!in) { perror(file); return 2; }
    }

    char tmp[] = "/tmp/blackbelt-c-XXXXXX";
    int fd = mkstemp(tmp);
    if (fd < 0) { perror("mkstemp"); if (file) fclose(in); return 2; }
    FILE *out = fdopen(fd, "wb");
    if (!out) { perror("fdopen"); close(fd); unlink(tmp); if (file) fclose(in); return 2; }
    int rc = copy_stream(in);
    if (file) fclose(in);
    fclose(out);
    if (rc) { unlink(tmp); return 2; }

    const char *engine = getenv("BBEA_ENGINE_CMD");
    if (!engine || !*engine) engine = "bin/blackbelt-engine.sh";

    char command[4096];
    snprintf(command, sizeof(command), "cat '%s' | '%s'", tmp, engine);
    int status = system(command);
    unlink(tmp);
    if (status == -1) return 3;
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return 3;
}
