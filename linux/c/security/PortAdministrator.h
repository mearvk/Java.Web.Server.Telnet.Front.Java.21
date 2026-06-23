/* Auto-generated from source/security/PortAdministrator.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct PortAdministrator PortAdministrator;

/* Constructor / Destructor */
PortAdministrator* PortAdministrator_new(void);
void PortAdministrator_free(PortAdministrator* self);

void* PortAdministrator_methods(PortAdministrator* self, void* provided);

