/* Auto-generated from source/telnet/TelnetMessageQueue.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct TelnetMessageQueue TelnetMessageQueue;

/* Constructor / Destructor */
TelnetMessageQueue* TelnetMessageQueue_new(void);
void TelnetMessageQueue_free(TelnetMessageQueue* self);

void TelnetMessageQueue_add(TelnetMessageQueue* self, void* message);
void TelnetMessageQueue_remove(TelnetMessageQueue* self, void* message);
void TelnetMessageQueue_sleep(TelnetMessageQueue* self, void* message);
int TelnetMessageQueue_size(TelnetMessageQueue* self);
void TelnetMessageQueue_delete(TelnetMessageQueue* self, void* message);
void* TelnetMessageQueue_StringBuffer(TelnetMessageQueue* self);

