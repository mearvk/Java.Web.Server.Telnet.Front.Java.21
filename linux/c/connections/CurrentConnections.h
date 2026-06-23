/* Auto-generated from source/connections/CurrentConnections.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct CurrentConnections CurrentConnections;

/* Constructor / Destructor */
CurrentConnections* CurrentConnections_new(void);
void CurrentConnections_free(CurrentConnections* self);

void CurrentConnections_add(CurrentConnections* self, void* connection);
void CurrentConnections_remove(CurrentConnections* self, void* socket);
void CurrentConnections_remove(CurrentConnections* self, void* connection);
int CurrentConnections_size(CurrentConnections* self);

