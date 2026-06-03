/* Auto-generated C implementation stub for source/bitcoin/time/flat/BitcoinPSTTimeDate.java */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "BitcoinPSTTimeDate.h"

struct BitcoinPSTTimeDate {
    /* TODO: fields translated from Java class */
    int _dummy;
};

BitcoinPSTTimeDate* BitcoinPSTTimeDate_new(void)
{
    BitcoinPSTTimeDate* self = malloc(sizeof(BitcoinPSTTimeDate));
    if(!self) return NULL;
    self->_dummy = 0;
    return self;
}

void BitcoinPSTTimeDate_free(BitcoinPSTTimeDate* self)
{
    if(!self) return;
    free(self);
}

