/* Auto-generated from source/telnet/TelnetInputBuilder.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct TelnetInputBuilder TelnetInputBuilder;

/* Constructor / Destructor */
TelnetInputBuilder* TelnetInputBuilder_new(void);
void TelnetInputBuilder_free(TelnetInputBuilder* self);

void* TelnetInputBuilder_StringBuffer(TelnetInputBuilder* self);
void* TelnetInputBuilder_TelnetMessageQueue(TelnetInputBuilder* self, void* arg);
void TelnetInputBuilder_run(TelnetInputBuilder* self);
void* TelnetInputBuilder_while(TelnetInputBuilder* self, void* arg);
void TelnetInputBuilder_setBuffer(TelnetInputBuilder* self, void* buffer);

