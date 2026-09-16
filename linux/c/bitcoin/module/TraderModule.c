/*
 * TraderModule.c — native Bitcoin module boundary.
 *
 * This file intentionally does not duplicate Java-side trading logic. Native
 * entry points are limited to safe lifecycle/message boundaries until their
 * semantics can be implemented and tested independently. In particular,
 * wallet deletion and transaction broadcasting remain disabled here.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TraderModule.h"

struct TraderModule {
    int initialized;
};

static void unsupported(const char* operation)
{
    fprintf(stderr, "[TraderModule] %s is not implemented in the native C layer.\n", operation);
}

TraderModule* TraderModule_new(void)
{
    TraderModule* self = calloc(1, sizeof(*self));
    if (!self) return NULL;
    self->initialized = 1;
    return self;
}

void TraderModule_free(TraderModule* self)
{
    free(self);
}

void* TraderModule_MessageOrderer(TraderModule* self, void* arg)
{
    (void)self;
    (void)arg;
    unsupported("MessageOrderer");
    return NULL;
}

void* TraderModule_BitcoinAsiaAndTokyoDate(TraderModule* self)
{
    (void)self;
    unsupported("BitcoinAsiaAndTokyoDate");
    return NULL;
}

void* TraderModule_BitcoinAmericaAndNewYorkDate(TraderModule* self)
{
    (void)self;
    unsupported("BitcoinAmericaAndNewYorkDate");
    return NULL;
}

void TraderModule_send_message_buf(TraderModule* self, const void* buffer, size_t length)
{
    (void)self;
    if (!buffer || length == 0) return;
    fwrite(buffer, 1, length, stdout);
    fputc('\n', stdout);
}

void TraderModule_send_message_str(TraderModule* self, const char* message)
{
    (void)self;
    if (!message) return;
    fprintf(stdout, "[TraderModule] message: %s\n", message);
}

void TraderModule_start_server_instance(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    unsupported("start_server_instance");
}

void TraderModule_load_wallet(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    unsupported("load_wallet; use BitcoinBase's authenticated Core boundary");
}

char* TraderModule_get_wallet_name(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    unsupported("get_wallet_name; use BitcoinBase's authenticated Core boundary");
    return NULL;
}

void* TraderModule_BufferedReader(TraderModule* self, void* input_stream)
{
    (void)self;
    (void)input_stream;
    unsupported("BufferedReader");
    return NULL;
}

void* TraderModule_StringBuilder(TraderModule* self)
{
    (void)self;
    unsupported("StringBuilder");
    return NULL;
}

void TraderModule_delete_wallet(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    fprintf(stderr, "[TraderModule] delete_wallet is disabled.\n");
}

void TraderModule_unload_wallet(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    unsupported("unload_wallet; use BitcoinBase's authenticated Core boundary");
}

void TraderModule_rename_wallet(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    unsupported("rename_wallet; Bitcoin Core has no native rename RPC");
}

void TraderModule_add_new_wallet(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    unsupported("add_new_wallet; use BitcoinBase's authenticated Core boundary");
}

void TraderModule_send_local_wallet_to_remote_wallet(TraderModule* self, const char* url)
{
    (void)self;
    (void)url;
    fprintf(stderr, "[TraderModule] transaction broadcasting is disabled in the native module.\n");
}
