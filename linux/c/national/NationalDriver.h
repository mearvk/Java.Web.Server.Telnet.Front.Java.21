/* Auto-generated from source/national/NationalDriver.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct NationalDriver NationalDriver;

/* Constructor / Destructor */
NationalDriver* NationalDriver_new(void);
void NationalDriver_free(NationalDriver* self);

void NationalDriver_record(NationalDriver* self, char* reference);
char* NationalDriver_static_extractClassName(char* reference);
void* NationalDriver_name(NationalDriver* self, void* earlier);
void* NationalDriver_getGroupedStartupReferences(NationalDriver* self);
void* NationalDriver_getGroupNames(NationalDriver* self);
void NationalDriver_printCorrectedOrder(NationalDriver* self);
void* NationalDriver_if(NationalDriver* self, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_if(NationalDriver* self, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_if(NationalDriver* self, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_if(NationalDriver* self, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_if(NationalDriver* self, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_if(NationalDriver* self, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_Entry(NationalDriver* self, void* arg, void* arg, void* arg, void* arg);
void* NationalDriver_timestamp(NationalDriver* self, void* arg);
void* NationalDriver_unknown(NationalDriver* self, void* arg);
void* NationalDriver_if(NationalDriver* self, void* _1);
void* NationalDriver_if(NationalDriver* self, void* _1);
long NationalDriver_static_extractTimestamp(char* reference);
void NationalDriver_clear(NationalDriver* self);

