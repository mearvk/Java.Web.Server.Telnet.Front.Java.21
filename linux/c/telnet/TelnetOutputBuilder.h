/* Auto-generated from source/telnet/TelnetOutputBuilder.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct TelnetOutputBuilder TelnetOutputBuilder;

/* Constructor / Destructor */
TelnetOutputBuilder* TelnetOutputBuilder_new(void);
void TelnetOutputBuilder_free(TelnetOutputBuilder* self);

void* TelnetOutputBuilder_TelnetMessageQueue(TelnetOutputBuilder* self, void* arg);
void TelnetOutputBuilder_run(TelnetOutputBuilder* self);

