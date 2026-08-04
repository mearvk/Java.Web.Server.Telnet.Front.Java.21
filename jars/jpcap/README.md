# Jpcap — Java Packet Capture Library

**Source:** https://github.com/jpcap/jpcap  
**License:** LGPL-2.1  
**Purpose:** Network packet capture, inspection, and injection for Java applications

## What It Provides

- Raw packet capture via libpcap (Linux) / WinPcap (Windows)
- Protocol dissection: Ethernet, IP, TCP, UDP, ICMP, ARP
- Packet injection (send crafted packets)
- Interface enumeration
- BPF filter support (Berkeley Packet Filter)

## Usage in NitroWebExpress

Jpcap powers the network monitoring and stability analysis subsystem:
- Real-time packet capture for connection quality assessment
- Network interface discovery and health monitoring
- Protocol-level traffic analysis
- Connection stability metrics (jitter, loss, reordering)

## Build

```bash
./fetch-jpcap.sh
```

Requires: `libpcap-dev`, JDK 21+, Maven (or uses bundled mvnw)

## Files

```
fetch-jpcap.sh    — Download source + build JAR
jpcap-src/        — Full source tree (after fetch)
jpcap-*.jar       — Built JAR (after fetch)
README.md         — This file
```
