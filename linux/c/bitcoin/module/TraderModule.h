/* TraderModule C interface aligned with the hardened Bitcoin boundary. */
#pragma once

#include <stddef.h>

typedef struct TraderModule TraderModule;

TraderModule* TraderModule_new(void);
void TraderModule_free(TraderModule* self);

/* Unsupported Java-only helpers return NULL until a native implementation exists. */
void* TraderModule_MessageOrderer(TraderModule* self, void* arg);
void* TraderModule_BitcoinAsiaAndTokyoDate(TraderModule* self);
void* TraderModule_BitcoinAmericaAndNewYorkDate(TraderModule* self);
void* TraderModule_BufferedReader(TraderModule* self, void* input_stream);
void* TraderModule_StringBuilder(TraderModule* self);

/* C has no overloads: keep buffer and string entry points distinct. */
void TraderModule_send_message_buf(TraderModule* self, const void* buffer, size_t length);
void TraderModule_send_message_str(TraderModule* self, const char* message);

void TraderModule_start_server_instance(TraderModule* self, const char* url);
void TraderModule_load_wallet(TraderModule* self, const char* url);
char* TraderModule_get_wallet_name(TraderModule* self, const char* url);
void TraderModule_delete_wallet(TraderModule* self, const char* url);
void TraderModule_unload_wallet(TraderModule* self, const char* url);
void TraderModule_rename_wallet(TraderModule* self, const char* url);
void TraderModule_add_new_wallet(TraderModule* self, const char* url);
void TraderModule_send_local_wallet_to_remote_wallet(TraderModule* self, const char* url);
