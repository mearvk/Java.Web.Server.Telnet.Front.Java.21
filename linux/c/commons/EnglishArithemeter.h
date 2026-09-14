/* Auto-generated from source/commons/EnglishArithemeter.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct EnglishArithemeter EnglishArithemeter;

/* Constructor / Destructor */
EnglishArithemeter* EnglishArithemeter_new(void);
void EnglishArithemeter_free(EnglishArithemeter* self);

void* EnglishArithemeter_Result(EnglishArithemeter* self);
char* EnglishArithemeter_olympics(EnglishArithemeter* self, int number);
void EnglishArithemeter_convert(EnglishArithemeter* self, long number);
void* EnglishArithemeter_DecimalFormat(EnglishArithemeter* self, void* arg);
void* EnglishArithemeter_StringBuilder(EnglishArithemeter* self);

