/* Auto-generated from source/connections/ConnectionPoller.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct ConnectionPoller ConnectionPoller;

/* Constructor / Destructor */
ConnectionPoller* ConnectionPoller_new(void);
void ConnectionPoller_free(ConnectionPoller* self);

void ConnectionPoller_run(ConnectionPoller* self);
void* ConnectionPoller_EnglishArithemeter(ConnectionPoller* self, void* arg);
void* ConnectionPoller_Date(ConnectionPoller* self);
void* ConnectionPoller_StringBuffer(ConnectionPoller* self, void* arg);
void* ConnectionPoller_Date(ConnectionPoller* self, void* arg);
void* ConnectionPoller_StringBuffer(ConnectionPoller* self, void* arg);
void* ConnectionPoller_BufferedReader(ConnectionPoller* self, void* InputStreamReader_connection_socket_getInputStream_);
void* ConnectionPoller_StringBuilder(ConnectionPoller* self);
void* ConnectionPoller_StringBuffer(ConnectionPoller* self, void* arg);
void* ConnectionPoller_StringBuffer(ConnectionPoller* self, void* arg);

