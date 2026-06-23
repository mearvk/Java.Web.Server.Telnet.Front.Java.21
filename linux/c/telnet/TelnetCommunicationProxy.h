/* Auto-generated from source/telnet/TelnetCommunicationProxy.java */
#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct TelnetCommunicationProxy TelnetCommunicationProxy;

/* Constructor / Destructor */
TelnetCommunicationProxy* TelnetCommunicationProxy_new(void);
void TelnetCommunicationProxy_free(TelnetCommunicationProxy* self);

void* TelnetCommunicationProxy_ProcessBuilder(TelnetCommunicationProxy* self);
void* TelnetCommunicationProxy_TelnetProxyCommunicator(TelnetCommunicationProxy* self, void* arg);
void* TelnetCommunicationProxy_TelnetOutputBuilder(TelnetCommunicationProxy* self, void* arg);
void* TelnetCommunicationProxy_TelnetInputBuilder(TelnetCommunicationProxy* self, void* arg);
void* TelnetCommunicationProxy_TelnetProxyCommunicator(TelnetCommunicationProxy* self, void* telnet_communication_proxy);
void TelnetCommunicationProxy_run(TelnetCommunicationProxy* self);
void* TelnetCommunicationProxy_Date(TelnetCommunicationProxy* self);

