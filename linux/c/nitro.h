#ifndef NITRO_H
#define NITRO_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    const char *host;
    int port;
    const char *thread_name;
    bool enabled;
} AESComponent;

typedef struct {
    const char *host;
    int port;
    const char *thread_name;
    bool enabled;
} BitcoinComponent;

typedef struct {
    AESComponent AES_COMPONENT;
    BitcoinComponent BITCOIN_COMPONENT;
} NitroBridge;

typedef struct {
    int PORT;
    const char *HOST;
    const char *THREAD_NAME;
    bool TELNET_PROXY_ENABLED;
    NitroBridge bridge;
} NitroWebExpress;

void NitroWebExpress_init(NitroWebExpress *n, int port, const char *host, const char *thread_name);
void NitroWebExpress_start(NitroWebExpress *n);

#ifdef __cplusplus
}
#endif

#endif // NITRO_H
