/* Auto-generated C implementation stub for source/national/NationalID.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "NationalID.h"

struct NationalID {
    /* TODO: fields translated from Java class */
    int _dummy;
};

NationalID* NationalID_new(void)
{
    NationalID* self = malloc(sizeof(NationalID));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void NationalID_free(NationalID* self)
{
    if(!self) return;
    free(self);
}

