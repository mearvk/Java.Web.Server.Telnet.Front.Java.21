/* Auto-generated from source/bitcoin/base/BitcoinBase.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct BitcoinBase BitcoinBase;

/* Constructor / Destructor */
BitcoinBase* BitcoinBase_new(void);
void BitcoinBase_free(BitcoinBase* self);

void* BitcoinBase_MessageOrderer(BitcoinBase* self, void* arg);
void* BitcoinBase_BitcoinAsiaAndTokyoDate(BitcoinBase* self);
void* BitcoinBase_BitcoinAmericaAndNewYorkDate(BitcoinBase* self);
void BitcoinBase_send_message(BitcoinBase* self, void* buffer);
void BitcoinBase_send_message(BitcoinBase* self, char* message);
void BitcoinBase_start_server_instance(BitcoinBase* self, void* url);
void BitcoinBase_load_wallet(BitcoinBase* self, void* url);
char* BitcoinBase_get_wallet_name(BitcoinBase* self, void* url);
void* BitcoinBase_BufferedReader(BitcoinBase* self, void* InputStreamReader_process_getInputStream_);
void* BitcoinBase_StringBuilder(BitcoinBase* self);
void BitcoinBase_delete_wallet(BitcoinBase* self, void* url);
void BitcoinBase_unload_wallet(BitcoinBase* self, void* url);
void BitcoinBase_rename_wallet(BitcoinBase* self, void* url);
void BitcoinBase_add_new_wallet(BitcoinBase* self, void* url);
void BitcoinBase_send_local_wallet_to_remote_wallet(BitcoinBase* self, void* url);

