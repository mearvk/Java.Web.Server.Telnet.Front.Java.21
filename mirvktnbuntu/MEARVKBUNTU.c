#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <curl/curl.h>
#include <sys/wait.h>

#define DEFAULT_OUT "/tmp/kernel.img"
#define POLL_INTERVAL 2

struct write_data {
    FILE *fp;
};

static size_t write_cb(void *ptr, size_t size, size_t nmemb, void *userdata) {
    struct write_data *wd = (struct write_data*)userdata;
    return fwrite(ptr, size, nmemb, wd->fp);
}

int download_file(const char *url, const char *outpath) {
    CURL *c = curl_easy_init();
    if (!c) return -1;
    FILE *fp = fopen(outpath, "wb");
    if (!fp) { curl_easy_cleanup(c); return -1; }
    struct write_data wd = { .fp = fp };

    curl_easy_setopt(c, CURLOPT_URL, url);
    curl_easy_setopt(c, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(c, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(c, CURLOPT_WRITEDATA, &wd);
    curl_easy_setopt(c, CURLOPT_USERAGENT, "kernel-loader/0.1");
    CURLcode rc = curl_easy_perform(c);
    fclose(fp);
    curl_easy_cleanup(c);
    return (rc == CURLE_OK) ? 0 : -1;
}

int file_exists(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0);
}

off_t file_size(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0) return -1;
    return st.st_size;
}

/* Basic sanity: check ELF magic or non-zero size. */
int basic_sanity(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    unsigned char magic[4];
    if (fread(magic, 1, 4, f) < 4) { fclose(f); return 0; }
    fclose(f);
    /* ELF magic */
    if (magic[0] == 0x7f && magic[1]=='E' && magic[2]=='L' && magic[3]=='F') return 1;
    /* Otherwise accept non-empty file (bzImage/gz/etc) */
    return (file_size(path) > 0);
}

int run_kexec_load(const char *kernel, const char *initrd, const char *cmdline) {
    pid_t pid = fork();
    if (pid < 0) return -1;
    if (pid == 0) {
        /* Child: exec kexec -l kernel [--initrd=...] --command-line="..." */
        char *args[10];
        int j = 0;
        args[j++] = "kexec";
        args[j++] = "-l";
        args[j++] = strdup(kernel);
        if (initrd) {
            size_t n = strlen("--initrd=") + strlen(initrd) + 1;
            char *s = malloc(n);
            snprintf(s, n, "--initrd=%s", initrd);
            args[j++] = s;
        }
        if (cmdline) {
            size_t n = strlen("--command-line=") + strlen(cmdline) + 1;
            char *s = malloc(n);
            snprintf(s, n, "--command-line=%s", cmdline);
            args[j++] = s;
        }
        args[j] = NULL;
        execvp("kexec", args);
        perror("execvp kexec failed");
        _exit(127);
    } else {
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }
}

void usage(const char *p) {
    fprintf(stderr,
        "Usage: %s [--url <raw-github-url>] [--path <local-file>] [--wait] [--initrd <path>] [--cmdline <string>] [--execute]\n"
        "Examples:\n"
        "  %s --url https://raw.githubusercontent.com/owner/repo/branch/vmlinuz --path /tmp/kernel.img\n"
        "  %s --path /tmp/kernel.img --wait --execute --initrd /tmp/initrd.img --cmdline \"root=/dev/ram0\"\n",
        p, p, p);
}

int main(int argc, char **argv) {
    const char *url = NULL;
    const char *path = DEFAULT_OUT;
    const char *initrd = NULL;
    const char *cmdline = NULL;
    int wait_mode = 0;
    int do_execute = 0;

    for (int i=1;i<argc;i++) {
        if (!strcmp(argv[i],"--url") && i+1<argc) { url = argv[++i]; }
        else if (!strcmp(argv[i],"--path") && i+1<argc) { path = argv[++i]; }
        else if (!strcmp(argv[i],"--wait")) { wait_mode = 1; }
        else if (!strcmp(argv[i],"--initrd") && i+1<argc) { initrd = argv[++i]; }
        else if (!strcmp(argv[i],"--cmdline") && i+1<argc) { cmdline = argv[++i]; }
        else if (!strcmp(argv[i],"--execute")) { do_execute = 1; }
        else { usage(argv[0]); return 1; }
    }

    if (url) {
        printf("Downloading kernel from: %s\n", url);
        if (download_file(url, path) != 0) {
            fprintf(stderr, "Download failed: %s\n", strerror(errno));
            return 2;
        }
        printf("Saved to %s\n", path);
    }

    if (wait_mode) {
        printf("Waiting for kernel file at %s ...\n", path);
        while (!file_exists(path)) {
            sleep(POLL_INTERVAL);
        }
        printf("File appeared: %s\n", path);
    }

    if (!file_exists(path)) {
        fprintf(stderr, "Kernel file not found: %s\n", path);
        return 3;
    }

    if (!basic_sanity(path)) {
        fprintf(stderr, "Basic sanity check failed for %s\n", path);
        return 4;
    }

    printf("Kernel present and looks sane: %s\n", path);
    printf("To stage the kernel: kexec -l %s", path);
    if (initrd) printf(" --initrd=%s", initrd);
    if (cmdline) printf(" --command-line='%s'", cmdline);
    printf("\n");
    if (!do_execute) {
        printf("Run the above command as root to stage. To immediately boot into it: kexec -e (or pass --execute to this program).\n");
        return 0;
    }

    /* Warning: executing kexec -e will reboot into the new kernel */
    printf("Staging kernel via kexec (requires root)...\n");
    int rc = run_kexec_load(path, initrd, cmdline);
    if (rc != 0) {
        fprintf(stderr, "kexec load returned %d\n", rc);
        return 5;
    }
    printf("kexec loaded. Execute 'kexec -e' to boot, or re-run with --execute to auto-run (dangerous).\n");
    return 0;
}
