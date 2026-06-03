#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "commons.h"
#include "international_common.h"
#include "national.h"
#include "nitro.h"

static const char *HASH = "0xDA717018470E213F";
static const int WEBEXPRESS_PORT = 49152;
static const int AES2_WEBEXPRESS_SERVER_SOCKET = 5512;
static const int BITCOIN_WEBEXPRESS_SERVER_SOCKET = 6682;

int main(void)
{
    printf("-\n");
    printf("[ Java National Finance Engine v.28.1.1 Software Processes Starting ]\n");
    printf(". Cryptography/Cryptology AES2 National Cryptolograph Enabled DSS 5.0 .\n");
    printf(". Bitcoin Lightweight Binary Trader 2.0 Enabled \xE2\x82\xBF Running on Bitcoin Open-Source v24.0 or newer .\n");
    printf(". Operating within and United to National Authority of US United States and State of California in Coalition of and for North Carolina her betterment .\n");
    printf(". ND51 North Carolina Labors & Standards A5501 ANationals Standards of Cary, NC 2807 .\n\n");

    InternationalCommonRails_IranianWedding_printSystemComponent(HASH);

    printf("-\n");

    CommonRails_printSystemComponent(HASH, 0, ". Java\u2122 National Finance Engine v.2811.1 v.11.1 .");
    CommonRails_printSystemComponent(HASH, 0, ". National NitroExpress\u2122 Web Engine Starting .");

    /* best-effort: attempt to reorder and clear startup entries */
    if (NationalDriver_printCorrectedOrder() != 0) {
        /* ignore errors and continue */
    }
    NationalDriver_clear();

    NitroWebExpress nitro;
    NitroWebExpress_init(&nitro, WEBEXPRESS_PORT, "localhost", "WEBEXPRESS_TELNET_PROXY_SERVER");

    nitro.PORT = WEBEXPRESS_PORT;
    nitro.HOST = "localhost";
    nitro.THREAD_NAME = "United States D500 WebExpress";
    nitro.TELNET_PROXY_ENABLED = true;

    nitro.bridge.AES_COMPONENT = (AESComponent){ .host = "localhost", .port = AES2_WEBEXPRESS_SERVER_SOCKET, .thread_name = "WEBEXPRESS_AES2_SERVER", .enabled = true };
    nitro.bridge.BITCOIN_COMPONENT = (BitcoinComponent){ .host = "localhost", .port = BITCOIN_WEBEXPRESS_SERVER_SOCKET, .thread_name = "WEBEXPRESS_BITCOIN_SERVER", .enabled = true };

    NitroWebExpress_start(&nitro);

    return 0;
}
