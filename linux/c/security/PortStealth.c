/* Auto-generated C implementation stub for source/security/PortStealth.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "PortStealth.h"

struct PortStealth {
    /* TODO: fields translated from Java class */
    int _dummy;
};

PortStealth* PortStealth_new(void)
{
    PortStealth* self = malloc(sizeof(PortStealth));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void PortStealth_free(PortStealth* self)
{
    if(!self) return;
    free(self);
}

