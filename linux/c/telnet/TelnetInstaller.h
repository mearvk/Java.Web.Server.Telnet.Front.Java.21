/* Auto-generated from source/telnet/TelnetInstaller.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct TelnetInstaller TelnetInstaller;

/* Constructor / Destructor */
TelnetInstaller* TelnetInstaller_new(void);
void TelnetInstaller_free(TelnetInstaller* self);

void* TelnetInstaller_ProcessBuilder(TelnetInstaller* self);
void* TelnetInstaller_BufferedReader(TelnetInstaller* self, void* InputStreamReader_process_getInputStream_);
void* TelnetInstaller_BufferedWriter(TelnetInstaller* self, void* OutputStreamWriter_process_getOutputStream_);

