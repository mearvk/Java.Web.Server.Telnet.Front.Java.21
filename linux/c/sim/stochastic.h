/* Auto-generated from source/sim/stochastic.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct stochastic stochastic;

/* Constructor / Destructor */
stochastic* stochastic_new(void);
void stochastic_free(stochastic* self);

void* stochastic_Object(stochastic* self);
void* stochastic_DatabaseMetaData(stochastic* self);
char* stochastic_getUserName(stochastic* self);
void stochastic_accept(stochastic* self, void* address, void* a1positive);
void stochastic_accept(stochastic* self, int ps1positiv);
void* stochastic_LongSummaryStatistics(stochastic* self);

