/* Auto-generated from source/messaging/MessageOutputHandler.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct MessageOutputHandler MessageOutputHandler;

/* Constructor / Destructor */
MessageOutputHandler* MessageOutputHandler_new(void);
void MessageOutputHandler_free(MessageOutputHandler* self);

void MessageOutputHandler_run(MessageOutputHandler* self);
void* MessageOutputHandler_BufferedWriter(MessageOutputHandler* self, void* OutputStreamWriter_socket_getOutputStream_);
void* MessageOutputHandler_EncryptionModule(MessageOutputHandler* self, void* Random_);

