# NWE Gateway — NAT Traversal for Home Deployments

## Problem

Home users running JWSTF/NitroWebExpress want to accept inbound traffic from
the public internet. However, home routers use NAT and stateful firewalls that
only permit outbound connections by default. Standard consumer internet packages
do not forward inbound port 80/443 traffic to a home machine.

## Solution: Hybrid Gateway

The NWE Gateway uses a two-phase approach:

```
┌───────────────────────────────────────────────────────────────────┐
│  PHASE 1: Try Direct (UPnP/NAT-PMP)                               │
│                                                                    │
│  Home Router supports UPnP?                                        │
│    YES → Open ports 80, 443, 8080, 23 on the router              │
│         → Verify reachability from outside                         │
│         → Register public IP with relay (directory only)           │
│         → MODE: DIRECT (fastest, zero relay overhead)              │
│                                                                    │
│    NO  → Fall through to Phase 2                                   │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
┌────────────────────────────────▼──────────────────────────────────┐
│  PHASE 2: Reverse Tunnel (Relay Mode)                              │
│                                                                    │
│  Open outbound SSH tunnel to relay server                          │
│    → Tunnel ports: local 80/443/8080/23 → relay:assigned_port     │
│    → Relay proxies inbound traffic through the tunnel              │
│    → MODE: RELAY (works behind any NAT, including CGNAT)           │
└───────────────────────────────────────────────────────────────────┘
```

## Architecture

```
                    INTERNET
                       │
         ┌─────────────┴─────────────┐
         │                           │
    Direct Mode                 Relay Mode
    (UPnP worked)               (UPnP failed)
         │                           │
         ▼                           ▼
┌─────────────────┐      ┌─────────────────────┐
│  Home Router    │      │  relay.mearvk.us     │
│  Port 80 → LAN │      │  (central console)   │
│  UPnP Mapped   │      │                      │
└────────┬────────┘      │  nginx reverse proxy │
         │               │         │            │
         ▼               │    SSH tunnel        │
┌─────────────────┐      │    (outbound from    │
│  Home JWSTF     │      │     home → relay)    │
│  Apache:80      │      └──────────┬───────────┘
│  Tomcat:8080    │                 │
│  NWE:23         │      ┌──────────▼───────────┐
└─────────────────┘      │  Home JWSTF          │
                         │  (behind NAT)        │
                         │  SSH tunnel open      │
                         └──────────────────────┘
```

## Components

| File | Role | Runs On |
|------|------|---------|
| `nwe-gateway` | Client daemon (home instance) | Home machine |
| `nwe-relay` | Central console server | Public VPS/cloud |
| `gateway.conf` | Gateway configuration | Home machine |
| `nwe-gateway.service` | Systemd service (home) | Home machine |
| `nwe-relay.service` | Systemd service (server) | Public server |
| `install-gateway.sh` | Home instance installer | Home machine |

## Usage (Home User)

```bash
# Install (done automatically during OS install)
sudo bash gateway/install-gateway.sh

# Start
systemctl start nwe-gateway

# Check status
nwe-gateway status

# Test reachability
nwe-gateway test
```

## Usage (Relay Server)

```bash
# First-time setup on a public VPS
sudo bash -c 'install -m 755 nwe-relay /usr/local/bin/'
sudo nwe-relay setup
sudo nwe-relay start

# Monitor
nwe-relay status
nwe-relay list
```

## How External Users Reach a Home Instance

1. Home instance registers with relay at `relay.mearvk.us`
2. Relay assigns a subdomain: `myserver.relay.mearvk.us`
3. External user visits `http://myserver.relay.mearvk.us/`
4. In **direct mode**: relay DNS resolves to home's public IP (fast)
5. In **relay mode**: nginx proxies through the SSH tunnel (works everywhere)

## Security Considerations

- UPnP mappings are time-limited (1 hour lease, auto-renewed)
- SSH tunnel uses ed25519 keys (generated per-instance)
- Relay tunnel user is restricted (`ForceCommand /bin/true`, no PTY, no forwarding)
- Instance secrets authenticate registrations
- All relay traffic can be TLS-wrapped (certbot on nginx)
- Gateway health-checks every 2 minutes

## Why Not Just Port Forward Manually?

- CGNAT (Carrier-Grade NAT): Many ISPs put multiple homes behind one IP
- Consumer routers: Not all support port forwarding or UPnP
- Dynamic IPs: Home IPs change; the relay tracks and updates automatically
- Zero-config: The gateway figures it out — no router login needed
- Fallback: Even if everything fails locally, the relay path works

## Ethical Treatment

The gateway design respects the home user's network. It:
- Asks the router politely (UPnP) rather than exploiting it
- Removes port mappings cleanly on shutdown
- Never modifies router firmware or configuration files
- Falls back gracefully rather than forcing connectivity
- Uses standard, auditable protocols (SSH, HTTP, UPnP)
