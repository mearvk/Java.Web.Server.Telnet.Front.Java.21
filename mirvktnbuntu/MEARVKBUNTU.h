#ifndef MEARVKBUNTU_H
#define MEARVKBUNTU_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <sys/types.h> /* off_t */

#define DEFAULT_OUT "/tmp/kernel.img"
#define POLL_INTERVAL 2

struct write_data {
    FILE *fp;
};

int download_file(const char *url, const char *outpath);
int file_exists(const char *path);
off_t file_size(const char *path);
int basic_sanity(const char *path);
int run_kexec_load(const char *kernel, const char *initrd, const char *cmdline);
void usage(const char *prog);

#ifdef __cplusplus
}
#endif

#endif /* MEARVKBUNTU_H */
