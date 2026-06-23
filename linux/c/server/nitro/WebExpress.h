/* Auto-generated from source/server/nitro/WebExpress.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct WebExpress WebExpress;

/* Constructor / Destructor */
WebExpress* WebExpress_new(void);
void WebExpress_free(WebExpress* self);

void* WebExpress_MessageQueue(WebExpress* self, void* arg);
void* WebExpress_SecurityException(WebExpress* self, void* arg);
void* WebExpress_TelnetInstaller(WebExpress* self, void* arg);
void* WebExpress_TelnetCommunicationProxy(WebExpress* self, void* arg);
void* WebExpress_MessageQueueSorter(WebExpress* self, void* arg);
void* WebExpress_MessageQueueSorter(WebExpress* self, void* arg);

