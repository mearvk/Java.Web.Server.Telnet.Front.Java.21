/* Auto-generated from source/connections/Connection.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct Connection Connection;

/* Constructor / Destructor */
Connection* Connection_new(void);
void Connection_free(Connection* self);

void* Connection_Date(Connection* self);
void* Connection_SecurityException(Connection* self, void* arg);

