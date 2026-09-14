/* Auto-generated from source/connections/InternationalConnections.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct InternationalConnections InternationalConnections;

/* Constructor / Destructor */
InternationalConnections* InternationalConnections_new(void);
void InternationalConnections_free(InternationalConnections* self);

void* InternationalConnections_RecordedInternationalConnection(InternationalConnections* self);
void* InternationalConnections_Date(InternationalConnections* self);
void InternationalConnections_add(InternationalConnections* self, void* connection);
void* InternationalConnections_RecordedInternationalConnection(InternationalConnections* self);
void InternationalConnections_remove(InternationalConnections* self, void* socket);
void InternationalConnections_remove(InternationalConnections* self, void* connection);
int InternationalConnections_size(InternationalConnections* self);

