/* Auto-generated C implementation stub for source/bitcoin/time/flat/BitcoinESTTimeDate.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "BitcoinESTTimeDate.h"

struct BitcoinESTTimeDate {
    /* TODO: fields translated from Java class */
    int _dummy;
};

BitcoinESTTimeDate* BitcoinESTTimeDate_new(void)
{
    BitcoinESTTimeDate* self = malloc(sizeof(BitcoinESTTimeDate));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void BitcoinESTTimeDate_free(BitcoinESTTimeDate* self)
{
    if(!self) return;
    free(self);
}

