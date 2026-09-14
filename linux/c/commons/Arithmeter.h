/* Auto-generated from source/commons/Arithmeter.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct Arithmeter Arithmeter;

/* Constructor / Destructor */
Arithmeter* Arithmeter_new(void);
void Arithmeter_free(Arithmeter* self);

char* Arithmeter_convert(Arithmeter* self, int num);
void* Arithmeter_StringBuilder(Arithmeter* self);
void* Arithmeter_helper(Arithmeter* self, void* 1000);
char* Arithmeter_helper(Arithmeter* self, int num);
void* Arithmeter_if(Arithmeter* self, void* 20);
void* Arithmeter_if(Arithmeter* self, void* 100);

