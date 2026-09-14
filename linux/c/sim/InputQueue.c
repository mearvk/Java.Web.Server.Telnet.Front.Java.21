/* Auto-generated C implementation stub for source/sim/InputQueue.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "InputQueue.h"

struct InputQueue {
    /* TODO: fields translated from Java class */
    int _dummy;
};

InputQueue* InputQueue_new(void)
{
    InputQueue* self = malloc(sizeof(InputQueue));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void InputQueue_free(InputQueue* self)
{
    if(!self) return;
    free(self);
}

void InputQueue_add(InputQueue* self, void* connection)
{
    // TODO: implement translated logic from Java
}

void InputQueue_remove(InputQueue* self, void* connection)
{
    // TODO: implement translated logic from Java
}

void* InputQueue_peek(InputQueue* self)
{
    // TODO: implement translated logic from Java
    return (void*)0;
}

