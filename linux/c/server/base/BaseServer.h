/* Auto-generated from source/server/base/BaseServer.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct BaseServer BaseServer;

/* Constructor / Destructor */
BaseServer* BaseServer_new(void);
void BaseServer_free(BaseServer* self);

void* BaseServer_CurrentConnections(BaseServer* self);
void* BaseServer_RecordedConnections(BaseServer* self);
void* BaseServer_InternationalConnections(BaseServer* self);
void* BaseServer_SecurityException(BaseServer* self, void* arg);
void* BaseServer_ServerSocket(BaseServer* self, void* arg, void* arg, void* arg);
void* BaseServer_run(BaseServer* self);
void* BaseServer_SecurityException(BaseServer* self, void* arg);
void* BaseServer_ServerSocket(BaseServer* self, void* arg, void* arg, void* arg);
void BaseServer_run(BaseServer* self);
void* BaseServer_Connection(BaseServer* self, void* arg);
void* BaseServer_BufferedReader(BaseServer* self, void* InputStreamReader_connection_inputstream);
void* BaseServer_BufferedWriter(BaseServer* self, void* OutputStreamWriter_connection_outputstream);
void* BaseServer_ConnectionPoller(BaseServer* self, void* arg, void* arg, void* arg, void* arg);

