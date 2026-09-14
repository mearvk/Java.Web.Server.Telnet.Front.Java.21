#include <stdio.h>
#include "nitro.h"

void NitroWebExpress_init(NitroWebExpress *n, int port, const char *host, const char *thread_name)
{
    if (!n) return;
    n->PORT = port;
    n->HOST = host;
    n->THREAD_NAME = thread_name;
    n->TELNET_PROXY_ENABLED = false;
    n->bridge.AES_COMPONENT = (AESComponent){ .host = "", .port = 0, .thread_name = "", .enabled = false };
    n->bridge.BITCOIN_COMPONENT = (BitcoinComponent){ .host = "", .port = 0, .thread_name = "", .enabled = false };
}

void NitroWebExpress_start(NitroWebExpress *n)
{
    if (!n) return;
    printf("[NitroWebExpress] Starting on %s:%d (%s)\n", n->HOST ? n->HOST : "(null)", n->PORT, n->THREAD_NAME ? n->THREAD_NAME : "(null)");
    if (n->TELNET_PROXY_ENABLED) {
        printf("[NitroWebExpress] Telnet proxy enabled.\n");
    }
    if (n->bridge.AES_COMPONENT.enabled) {
        printf("[NitroWebExpress] AES bridge -> %s:%d (%s)\n", n->bridge.AES_COMPONENT.host, n->bridge.AES_COMPONENT.port, n->bridge.AES_COMPONENT.thread_name);
    }
    if (n->bridge.BITCOIN_COMPONENT.enabled) {
        printf("[NitroWebExpress] Bitcoin bridge -> %s:%d (%s)\n", n->bridge.BITCOIN_COMPONENT.host, n->bridge.BITCOIN_COMPONENT.port, n->bridge.BITCOIN_COMPONENT.thread_name);
    }
    printf("[NitroWebExpress] Startup complete (simulated).\n");
}
