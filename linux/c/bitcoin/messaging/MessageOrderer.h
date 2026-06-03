/* Auto-generated from source/bitcoin/messaging/MessageOrderer.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct MessageOrderer MessageOrderer;

/* Constructor / Destructor */
MessageOrderer* MessageOrderer_new(void);
void MessageOrderer_free(MessageOrderer* self);

void MessageOrderer_run(MessageOrderer* self);
void* MessageOrderer_messages(MessageOrderer* self, void* externally);
void* MessageOrderer_while(MessageOrderer* self, void* arg);
void MessageOrderer_add(MessageOrderer* self, void* bitcoin_message);
void MessageOrderer_remove(MessageOrderer* self, void* bitcoin_message);
void MessageOrderer_clear(MessageOrderer* self, void* bitcoin_message);
void* MessageOrderer_BitcoinMessage(MessageOrderer* self);

