/* Black Belt Ethical Auditor - alternate no-save launcher. */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

static int copy_argument(char **dst, int *outc, int max, const char *arg) {
    if (*outc >= max) return 0;
    dst[(*outc)++] = (char *)arg;
    return 1;
}

int main(int argc, char **argv) {
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--version")) {
            puts("blackbelt-2 1.0 (BBEA no-save)");
            return 0;
        }
    }

    char executable[PATH_MAX];
    ssize_t n = readlink("/proc/self/exe", executable, sizeof(executable) - 1);
    if (n < 0 || (size_t)n >= sizeof(executable) - 1) {
        perror("blackbelt-2: cannot locate executable");
        return 127;
    }
    executable[n] = '\0';
    char *slash = strrchr(executable, '/');
    if (!slash) {
        fprintf(stderr, "blackbelt-2: invalid executable path\n");
        return 127;
    }
    *slash = '\0';
    char blackbelt_c[PATH_MAX];
    if (snprintf(blackbelt_c, sizeof(blackbelt_c), "%s/blackbelt-c", executable) >= (int)sizeof(blackbelt_c)) {
        fprintf(stderr, "blackbelt-2: executable path is too long\n");
        return 127;
    }

    setenv("BBEA_NO_SAVE", "1", 1);

    /* This alternate binary is deliberately no-save: reject --save FILE rather
       than allowing the underlying standard binary to write a response file. */
    char *child_argv[argc + 2];
    int child_argc = 0;
    copy_argument(child_argv, &child_argc, argc + 1, blackbelt_c);
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--save")) {
            if (i + 1 < argc) ++i;
            fprintf(stderr, "blackbelt-2: --save is disabled; output will not be saved\n");
            continue;
        }
        if (!copy_argument(child_argv, &child_argc, argc + 1, argv[i])) return 2;
    }
    child_argv[child_argc] = NULL;

    execv(blackbelt_c, child_argv);
    perror("blackbelt-2: exec blackbelt-c");
    return 127;
}
