/* Auto-generated from source/sim/InputQueue.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct InputQueue InputQueue;

/* Constructor / Destructor */
InputQueue* InputQueue_new(void);
void InputQueue_free(InputQueue* self);

void InputQueue_add(InputQueue* self, void* connection);
void InputQueue_remove(InputQueue* self, void* connection);
void* InputQueue_peek(InputQueue* self);

