/* Auto-generated from source/messaging/MessageQueueSorter.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct MessageQueueSorter MessageQueueSorter;

/* Constructor / Destructor */
MessageQueueSorter* MessageQueueSorter_new(void);
void MessageQueueSorter_free(MessageQueueSorter* self);

void MessageQueueSorter_run(MessageQueueSorter* self);
void* MessageQueueSorter_while(MessageQueueSorter* self, void* arg);
void* MessageQueueSorter_EnglishArithemeter(MessageQueueSorter* self, void* arg);
void* MessageQueueSorter_BufferedWriter(MessageQueueSorter* self, void* OutputStreamWriter_message_socket_getOutputStream_);
void* MessageQueueSorter_EnglishArithemeter(MessageQueueSorter* self, void* arg);
void MessageQueueSorter_addMessage(MessageQueueSorter* self, void* message);
void* MessageQueueSorter_getMessageQueue(MessageQueueSorter* self);
int MessageQueueSorter_getMessageQueueSize(MessageQueueSorter* self);

