/* Auto-generated from source/messaging/MessageQueue.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct MessageQueue MessageQueue;

/* Constructor / Destructor */
MessageQueue* MessageQueue_new(void);
void MessageQueue_free(MessageQueue* self);

void MessageQueue_clear(MessageQueue* self);
void MessageQueue_send(MessageQueue* self, void* message);
void* MessageQueue_BufferedWriter(MessageQueue* self, void* OutputStreamWriter_message_socket_getOutputStream_);
void* MessageQueue_StringBuffer(MessageQueue* self);
void MessageQueue_add(MessageQueue* self, void* message);
void MessageQueue_remove(MessageQueue* self, void* message);
int MessageQueue_size(MessageQueue* self);
void* MessageQueue_StringBuffer(MessageQueue* self);

