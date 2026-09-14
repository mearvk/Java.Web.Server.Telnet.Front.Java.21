/* Auto-generated C implementation stub for source/security/PortKnockKnock.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "PortKnockKnock.h"

struct PortKnockKnock {
    /* TODO: fields translated from Java class */
    int _dummy;
};

PortKnockKnock* PortKnockKnock_new(void)
{
    PortKnockKnock* self = malloc(sizeof(PortKnockKnock));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void PortKnockKnock_free(PortKnockKnock* self)
{
    if(!self) return;
    free(self);
}

