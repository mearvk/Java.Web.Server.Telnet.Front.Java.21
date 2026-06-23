/* Bitcoin base — C interface mirroring source/bitcoin/base/BitcoinBase.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct BitcoinBase BitcoinBase;

/* Constructor / Destructor */
BitcoinBase* BitcoinBase_new(void);
void         BitcoinBase_free(BitcoinBase* self);

/* Core wallet operations (url is an optional hint, may be NULL) */
void  BitcoinBase_start_server_instance(BitcoinBase* self, const char* url);
void  BitcoinBase_load_wallet           (BitcoinBase* self, const char* url);
char* BitcoinBase_get_wallet_name       (BitcoinBase* self, const char* url);
void  BitcoinBase_delete_wallet         (BitcoinBase* self, const char* url);
void  BitcoinBase_unload_wallet         (BitcoinBase* self, const char* url);
void  BitcoinBase_rename_wallet         (BitcoinBase* self, const char* url);
void  BitcoinBase_add_new_wallet        (BitcoinBase* self, const char* url);
void  BitcoinBase_send_local_to_remote  (BitcoinBase* self, const char* url);

/* Messaging */
void  BitcoinBase_send_message_buf      (BitcoinBase* self, const char* buf, size_t len);
void  BitcoinBase_send_message_str      (BitcoinBase* self, const char* message);
