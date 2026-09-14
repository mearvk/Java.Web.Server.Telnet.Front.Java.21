/* Auto-generated C implementation stub for source/bitcoin/messaging/MessageOrderer.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "MessageOrderer.h"

struct MessageOrderer {
    /* TODO: fields translated from Java class */
    int _dummy;
};

MessageOrderer* MessageOrderer_new(void)
{
    MessageOrderer* self = malloc(sizeof(MessageOrderer));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void MessageOrderer_free(MessageOrderer* self)
{
    if(!self) return;
    free(self);
}

void MessageOrderer_run(MessageOrderer* self)
{
    // TODO: implement translated logic from Java
}

void* MessageOrderer_messages(MessageOrderer* self, void* externally)
{
    // TODO: implement translated logic from Java
    return (void*)0;
}

void* MessageOrderer_while(MessageOrderer* self, void* arg)
{
    // TODO: implement translated logic from Java
    return (void*)0;
}

void MessageOrderer_add(MessageOrderer* self, void* bitcoin_message)
{
    // TODO: implement translated logic from Java
}

void MessageOrderer_remove(MessageOrderer* self, void* bitcoin_message)
{
    // TODO: implement translated logic from Java
}

void MessageOrderer_clear(MessageOrderer* self, void* bitcoin_message)
{
    // TODO: implement translated logic from Java
}

void* MessageOrderer_BitcoinMessage(MessageOrderer* self)
{
    // TODO: implement translated logic from Java
    return (void*)0;
}

