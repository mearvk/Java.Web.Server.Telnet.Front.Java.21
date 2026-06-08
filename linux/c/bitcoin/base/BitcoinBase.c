/*
 * BitcoinBase.c — functional C implementation
 * Mirrors source/bitcoin/base/BitcoinBase.java
 * Uses popen()/system() to invoke bitcoin-cli / bitcoind,
 * matching the Runtime.getRuntime().exec() pattern in Java.
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "BitcoinBase.h"

/* ------------------------------------------------------------------ */
/* Configuration — mirrors Java protected final String constants        */
/* ------------------------------------------------------------------ */
#define BITCOIN_CLI          "bitcoin-cli"
#define BITCOIND             "bitcoind"
#define BITCOIN_ROOT_PASSWORD ""
#define BITCOIN_PORT          ""

/* Wallet name used throughout — matches Java "United States" */
#define WALLET_NAME          "United States"

/* Block storage path — matches Java delete_wallet() */
#define BLOCK_STORAGE_DIR    "/mnt/blockstorage"
#define BLOCK_STORAGE_VER    "24"

/* Output buffer for get_wallet_name() */
#define RESULT_BUF_SIZE      4096

/* ------------------------------------------------------------------ */
/* Internal helpers                                                     */
/* ------------------------------------------------------------------ */

/** Build the common rpc flags shared by every bitcoin-cli call. */
static void rpc_flags(char* out, size_t out_size)
{
    snprintf(out, out_size,
             "-rpcpassword=%s -rpcport=%s",
             BITCOIN_ROOT_PASSWORD, BITCOIN_PORT);
}

/**
 * Run cmd and return a malloc'd string containing all stdout output,
 * or NULL on error.  Caller must free().
 */
static char* run_and_capture(const char* cmd)
{
    FILE* fp = popen(cmd, "r");
    if (!fp)
    {
        fprintf(stderr, "[BitcoinBase] popen failed: %s\n", cmd);
        return NULL;
    }

    char*  result = malloc(RESULT_BUF_SIZE);
    size_t pos    = 0;

    if (result)
    {
        char line[256];
        while (fgets(line, sizeof(line), fp) && pos + strlen(line) + 1 < RESULT_BUF_SIZE)
        {
            size_t n = strlen(line);
            memcpy(result + pos, line, n);
            pos += n;
        }
        result[pos] = '\0';
    }

    pclose(fp);
    return result;
}

/** Fire-and-forget: run cmd, print exit code. */
static void run_cmd(const char* cmd)
{
    fprintf(stdout, "[BitcoinBase] exec: %s\n", cmd);
    int rc = system(cmd);
    if (rc != 0)
        fprintf(stderr, "[BitcoinBase] command exited with code %d\n", rc);
}

/* ------------------------------------------------------------------ */
/* Struct                                                               */
/* ------------------------------------------------------------------ */

struct BitcoinBase {
    char hash[32];          /* mirrors protected String hash */
};

/* ------------------------------------------------------------------ */
/* Constructor / Destructor                                             */
/* ------------------------------------------------------------------ */

BitcoinBase* BitcoinBase_new(void)
{
    BitcoinBase* self = malloc(sizeof(BitcoinBase));
    if (!self) return NULL;
    strncpy(self->hash, "0xDA717018470E213F", sizeof(self->hash) - 1);
    self->hash[sizeof(self->hash) - 1] = '\0';
    fprintf(stdout, "[BitcoinBase] initialised hash=%s\n", self->hash);
    return self;
}

void BitcoinBase_free(BitcoinBase* self)
{
    if (!self) return;
    free(self);
}

/* ------------------------------------------------------------------ */
/* start_server_instance — launches bitcoind                           */
/* mirrors: Runtime.getRuntime().exec(BITCOIND + " " + BITCOIND_START_ARGS) */
/* ------------------------------------------------------------------ */

void BitcoinBase_start_server_instance(BitcoinBase* self, const char* url)
{
    (void)url;  /* url is informational in Java; not used by bitcoind */

    char flags[256];
    rpc_flags(flags, sizeof(flags));

    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "%s -regtest -daemon %s",
             BITCOIND, flags);

    run_cmd(cmd);
}

/* ------------------------------------------------------------------ */
/* load_wallet                                                          */
/* mirrors: bitcoin-cli -named loadwallet ... wallet_name="United States" */
/* ------------------------------------------------------------------ */

void BitcoinBase_load_wallet(BitcoinBase* self, const char* url)
{
    (void)url;

    char flags[256];
    rpc_flags(flags, sizeof(flags));

    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "%s %s -named loadwallet wallet_name=\"%s\"",
             BITCOIN_CLI, flags, WALLET_NAME);

    run_cmd(cmd);
}

/* ------------------------------------------------------------------ */
/* get_wallet_name                                                      */
/* mirrors: bitcoin-cli -named getwalletinfo ...                       */
/* Returns malloc'd string; caller must free().  Returns "-1" on error. */
/* ------------------------------------------------------------------ */

char* BitcoinBase_get_wallet_name(BitcoinBase* self, const char* url)
{
    (void)url;

    char flags[256];
    rpc_flags(flags, sizeof(flags));

    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "%s %s -named getwalletinfo",
             BITCOIN_CLI, flags);

    char* output = run_and_capture(cmd);
    if (!output || output[0] == '\0')
    {
        free(output);
        char* err = malloc(3);
        if (err) strcpy(err, "-1");
        return err;
    }

    fprintf(stdout, "[BitcoinBase] get_wallet_name: %s\n", output);
    return output;   /* caller must free */
}

/* ------------------------------------------------------------------ */
/* delete_wallet                                                        */
/* mirrors: rm -r <wallet_dir>                                         */
/* ------------------------------------------------------------------ */

void BitcoinBase_delete_wallet(BitcoinBase* self, const char* url)
{
    char* wallet_name = BitcoinBase_get_wallet_name(self, url);

    char wallet_dir[512];
    snprintf(wallet_dir, sizeof(wallet_dir),
             "%s/%s/regtest/wallets",
             BLOCK_STORAGE_DIR, BLOCK_STORAGE_VER);

    char cmd[768];
    snprintf(cmd, sizeof(cmd), "rm -r \"%s\"", wallet_dir);

    free(wallet_name);
    run_cmd(cmd);
}

/* ------------------------------------------------------------------ */
/* unload_wallet                                                        */
/* mirrors: bitcoin-cli -named unloadwallet wallet_name="United States" */
/* ------------------------------------------------------------------ */

void BitcoinBase_unload_wallet(BitcoinBase* self, const char* url)
{
    (void)url;

    char flags[256];
    rpc_flags(flags, sizeof(flags));

    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "%s %s -named unloadwallet wallet_name=\"%s\"",
             BITCOIN_CLI, flags, WALLET_NAME);

    run_cmd(cmd);
}

/* ------------------------------------------------------------------ */
/* rename_wallet                                                        */
/* NOTE: bitcoin-cli has no rename command natively; this is a no-op   */
/* placeholder matching the Java empty-string BITCOIN_CLI_RENAME_WALLET_ARGS */
/* ------------------------------------------------------------------ */

void BitcoinBase_rename_wallet(BitcoinBase* self, const char* url)
{
    (void)url;
    fprintf(stdout, "[BitcoinBase] rename_wallet: no-op (no native bitcoin-cli rename command)\n");
}

/* ------------------------------------------------------------------ */
/* add_new_wallet                                                       */
/* mirrors: bitcoin-cli createwallet ...                               */
/* ------------------------------------------------------------------ */

void BitcoinBase_add_new_wallet(BitcoinBase* self, const char* url)
{
    (void)url;

    char flags[256];
    rpc_flags(flags, sizeof(flags));

    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "%s %s createwallet \"%s\"",
             BITCOIN_CLI, flags, WALLET_NAME);

    run_cmd(cmd);
}

/* ------------------------------------------------------------------ */
/* send_local_to_remote                                                 */
/* Placeholder — args string is empty in Java (BITCOIN_CLI_SEND_LOCAL_WALLET_TO_REMOTE_WALLET_ARGS = "") */
/* ------------------------------------------------------------------ */

void BitcoinBase_send_local_to_remote(BitcoinBase* self, const char* url)
{
    (void)url;
    fprintf(stdout, "[BitcoinBase] send_local_to_remote: not yet configured (empty args)\n");
}

/* ------------------------------------------------------------------ */
/* send_message variants                                                */
/* ------------------------------------------------------------------ */

void BitcoinBase_send_message_buf(BitcoinBase* self, const char* buf, size_t len)
{
    (void)self;
    /* Write the buffer to stdout as a simple pass-through */
    fwrite(buf, 1, len, stdout);
    fputc('\n', stdout);
}

void BitcoinBase_send_message_str(BitcoinBase* self, const char* message)
{
    (void)self;
    if (message)
        fprintf(stdout, "[BitcoinBase] message: %s\n", message);
}
