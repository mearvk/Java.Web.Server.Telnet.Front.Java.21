/* Auto-generated from source/connections/RecordedConnections.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct RecordedConnections RecordedConnections;

/* Constructor / Destructor */
RecordedConnections* RecordedConnections_new(void);
void RecordedConnections_free(RecordedConnections* self);

void* RecordedConnections_RecordedConnection(RecordedConnections* self);
void* RecordedConnections_Date(RecordedConnections* self);
void RecordedConnections_add(RecordedConnections* self, void* connection);
void* RecordedConnections_RecordedConnection(RecordedConnections* self);
void RecordedConnections_remove(RecordedConnections* self, void* socket);
void RecordedConnections_remove(RecordedConnections* self, void* connection);
int RecordedConnections_size(RecordedConnections* self);

