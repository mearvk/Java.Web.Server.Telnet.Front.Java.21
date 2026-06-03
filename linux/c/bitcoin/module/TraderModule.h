/* Auto-generated from source/bitcoin/module/TraderModule.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct TraderModule TraderModule;

/* Constructor / Destructor */
TraderModule* TraderModule_new(void);
void TraderModule_free(TraderModule* self);

void* TraderModule_MessageOrderer(TraderModule* self, void* arg);
void* TraderModule_BitcoinAsiaAndTokyoDate(TraderModule* self);
void* TraderModule_BitcoinAmericaAndNewYorkDate(TraderModule* self);
void TraderModule_send_message(TraderModule* self, void* buffer);
void TraderModule_send_message(TraderModule* self, char* message);
void TraderModule_start_server_instance(TraderModule* self, void* url);
void TraderModule_load_wallet(TraderModule* self, void* url);
char* TraderModule_get_wallet_name(TraderModule* self, void* url);
void* TraderModule_BufferedReader(TraderModule* self, void* InputStreamReader_process_getInputStream_);
void* TraderModule_StringBuilder(TraderModule* self);
void TraderModule_delete_wallet(TraderModule* self, void* url);
void TraderModule_unload_wallet(TraderModule* self, void* url);
void TraderModule_rename_wallet(TraderModule* self, void* url);
void TraderModule_add_new_wallet(TraderModule* self, void* url);
void TraderModule_send_local_wallet_to_remote_wallet(TraderModule* self, void* url);

