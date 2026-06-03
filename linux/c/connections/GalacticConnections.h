/* Auto-generated from source/connections/GalacticConnections.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct GalacticConnections GalacticConnections;

/* Constructor / Destructor */
GalacticConnections* GalacticConnections_new(void);
void GalacticConnections_free(GalacticConnections* self);

void* GalacticConnections_RecordedGalacticConnection(GalacticConnections* self);
void* GalacticConnections_Date(GalacticConnections* self);
void GalacticConnections_add(GalacticConnections* self, void* connection);
void* GalacticConnections_RecordedGalacticConnection(GalacticConnections* self);
void GalacticConnections_remove(GalacticConnections* self, void* socket);
void GalacticConnections_remove(GalacticConnections* self, void* connection);
int GalacticConnections_size(GalacticConnections* self);

