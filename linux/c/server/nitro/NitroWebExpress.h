/* Auto-generated from source/server/nitro/NitroWebExpress.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct NitroWebExpress NitroWebExpress;

/* Constructor / Destructor */
NitroWebExpress* NitroWebExpress_new(void);
void NitroWebExpress_free(NitroWebExpress* self);

void* NitroWebExpress_Aspect(NitroWebExpress* self, void* arg);
void* NitroWebExpress_NationalID(NitroWebExpress* self);
void* NitroWebExpress_run(NitroWebExpress* self);
void* NitroWebExpress_super(NitroWebExpress* self, void* arg, void* arg, void* arg, void* arg);
void* NitroWebExpress_EncryptionModule(NitroWebExpress* self, void* Random_RANDOM);
void* NitroWebExpress_TraderModule(NitroWebExpress* self, void* arg, void* ADS5_0_);
void* NitroWebExpress_Aspect(NitroWebExpress* self, void* WEBEXPRESS);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void* NitroWebExpress_MessageQueueSorter(NitroWebExpress* self, void* arg);
void* NitroWebExpress_MessageQueue(NitroWebExpress* self, void* arg);
void* NitroWebExpress_AESCompliant(NitroWebExpress* self, void* HOST, void* PORT, void* THREAD_NAME, void* TELNET_PROXY_ENABLED);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void* NitroWebExpress_AESCompliant(NitroWebExpress* self);
void* NitroWebExpress_MessageOutputRecord(NitroWebExpress* self);
void* NitroWebExpress_MessageOutputHandler(NitroWebExpress* self);
void NitroWebExpress_send_message(NitroWebExpress* self, void* buffer);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void NitroWebExpress_send_message(NitroWebExpress* self, char* message);
void* NitroWebExpress_MessageQueue(NitroWebExpress* self, void* arg);
void* NitroWebExpress_BitcoinCompliant(NitroWebExpress* self, void* host, void* port, void* thread_name, void* telnet_proxy_enabled);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void* NitroWebExpress_BitcoinCompliant(NitroWebExpress* self);
void* NitroWebExpress_MessageOutputRecord(NitroWebExpress* self);
void* NitroWebExpress_MessageOutputHandler(NitroWebExpress* self);
void NitroWebExpress_send_message(NitroWebExpress* self, void* buffer);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void NitroWebExpress_send_message(NitroWebExpress* self, char* message);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void* NitroWebExpress_MessageQueueSorter(NitroWebExpress* self, void* web_express);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void NitroWebExpress_run(NitroWebExpress* self);
void* NitroWebExpress_EnglishArithemeter(NitroWebExpress* self, void* arg);
void* NitroWebExpress_BufferedWriter(NitroWebExpress* self, void* OutputStreamWriter_message_socket_getOutputStream_);
void* NitroWebExpress_EnglishArithemeter(NitroWebExpress* self, void* arg);
void NitroWebExpress_addMessage(NitroWebExpress* self, void* message);
void* NitroWebExpress_SecurityException(NitroWebExpress* self, void* arg);
void* NitroWebExpress_getMessageQueue(NitroWebExpress* self);
int NitroWebExpress_getMessageQueueSize(NitroWebExpress* self);

