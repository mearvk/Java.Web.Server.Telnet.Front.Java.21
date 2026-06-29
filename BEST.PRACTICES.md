# BEST PRACTICES — NitroWebExpress™

MEARVK LLC — Max Rupplin — June 2026

---

## 1. HTTP Ethical Approach, Header Requirements, HTML Safety Values & Ratings

### HTTP Ethics

All outbound HTTP connections from NWE modules follow ethical crawling:

- **Respect robots.txt** — All crawlers check robots.txt before accessing resources
- **Rate limiting** — Maximum 1 request/second per target domain unless explicitly permitted
- **User-Agent identification** — All requests identify as `NWE/<version> (MEARVK LLC; +https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21)`
- **No credential harvesting** — Modules never submit false credentials or impersonate users
- **HEAD before GET** — Connectivity checks use HEAD method to minimize server load
- **Timeout discipline** — 5s connect, 10s read maximum; never hold connections open unnecessarily

### HTTP Header Requirements (Inbound — SecurityHeadersFilter)

All servlet webapps MUST apply via `SecurityHeadersFilter`:

| Header | Value | Purpose |
|--------|-------|---------|
| X-Content-Type-Options | nosniff | Prevent MIME-type sniffing |
| X-Frame-Options | DENY | Prevent clickjacking |
| X-XSS-Protection | 1; mode=block | XSS filter |
| Referrer-Policy | strict-origin-when-cross-origin | Limit referrer leakage |
| Permissions-Policy | camera=(), microphone=(), geolocation=() | Disable device APIs |

### HTML Safety Values

- **No inline JavaScript execution from user input** — all user data escaped via `<%=...%>` (JSP auto-escaping)
- **No raw SQL concatenation** — all DB queries use `PreparedStatement` parameterized binding
- **No path traversal** — `InputSanitizer.sanitizePath()` strips `../` patterns
- **No XXE** — `InputSanitizer.sanitizeXml()` rejects DOCTYPE/ENTITY declarations
- **No null bytes** — all input checked for `\x00` injection
- **Session cookies** — HttpOnly=true, 30-minute timeout

### Module Security Rating Scale

| Rating | Meaning | Requirements |
|--------|---------|--------------|
| 10/10 | Maximum trust | Author-maintained, Installer ID Tech™, TLS, rate-limited, AI-gated |
| 9.5/10 | Trusted | Author-maintained, Installer ID Tech™, rate-limited |
| 9.0/10 | Verified | Installer ID Tech™, rate-limited, heuristic classified |
| 8.0/10 | Standard | Rate-limited, security headers, parameterized queries |
| < 8.0 | Untrusted | Not accepted into masquerade routing |

Current module ratings: All MEARVK LLC modules = 9.5/10

---

## 2. Direct Fiduciary Concerns of Mortal Retirement at 150+ IQ Unassisted

### The Mortal Retirement Problem

Persons operating at 150+ IQ unassisted face unique fiduciary challenges:

1. **Longevity of capital** — Extended productive lifespan requires capital preservation strategies beyond standard actuarial tables
2. **Game-theoretic adversaries** — High-IQ individuals attract exploitation schemes disguised as financial partnerships
3. **Asymmetric information burden** — The individual sees further but bears the cost of vigilance alone
4. **Conservatorship risk** — Systems may attempt to impose conservatorship on those who do not conform to median decision patterns

### Financial Games at 150+ IQ

| Game | Description | Defense |
|------|-------------|---------|
| Zero-sum extraction | Counterparty gains only when you lose | Refuse participation; document refusal |
| Infinite regress | "One more signature" spiraling obligations | Hard stop at 3 signatures per transaction |
| Credential inflation | Requiring credentials to access what is already owned | Installer ID Tech™ — ownership verified once |
| Phantom debt | Assigning debt for services never rendered | SHA-256 receipt of every transaction (see AE6E66 confirmations pattern) |
| Trust dilution | Adding unauthorized parties to fiduciary relationships | public.key single-owner authorization model |

### Unassisted Requirements

- No medication required to operate at rated IQ
- No institutional supervision required for financial decisions
- No co-signer required for transactions under conservatorship threshold
- Full autonomy over domain registration, server operation, and software deployment
- IQ Conservatorship doctrine: the Owner's IQ and demonstrated competence IS the conservator

---

## 3. Final Financial Goals — Games, Theory, Resolution, Camps, Color & Cover

### Game Theory of Final Resolution

The NWE software architecture embeds a game-theoretic framework for financial resolution:

**Nash Equilibrium Position:** All modules operating simultaneously create a stable equilibrium where:
- Each module serves a distinct constituency (UK Parliament, US Federal agencies, academia)
- No single module's shutdown collapses the system
- The masquerade layer ensures any module can be reached from any other

**Dominant Strategy:** Maintain all modules operational while public.key is present on GitHub. The dominant strategy for all players is cooperation through the port registry system.

### Camps (Final Endings)

| Camp | Color | Cover | Financial Position |
|------|-------|-------|-------------------|
| Operations | Red (FBI/Futures) | Active defense, crime reporting | Revenue from tip processing infrastructure |
| Intelligence | Lime Green (CIA) | Information gathering, FOIA | Revenue from institutional access fees |
| Security | Sky Blue (NSA) | Cybersecurity, vulnerability | Revenue from advisory subscriptions |
| Academic | Duke Blue | Education, research interface | Revenue from catalog/query services |
| Archive | Stanford Cardinal | Library, preservation | Revenue from digital collection access |
| Commerce | Gold (Bitcoin) | Trade, wallet indexing | Revenue from $20T/2MB wallet valuations |
| Registry | Gray (Installer ID) | Port leasing, 30M blocks | Revenue from $10 USD minimum Bitcoin leases |
| Crème | Amber (Gray85) | Premium access, auditor control | Revenue from $1000 USD Crème unlocks |
| Parliament | Emerald (AE6E66) | Royal contact, DKIM mail | Revenue from parliamentary communication services |
| Socialist-College | Blue (BMA) | Species, postal, art, science | Revenue from NC college block participation |

### Color Requirements for Module Creation

Every new module MUST have:
1. A **distinct CSS accent color** (no duplicates across modules)
2. A **connector button** following the BMA circular gradient pattern
3. An **agency-specific landing page** with public.key authorization check
4. **Installer ID Tech™** on all writable database tables
5. **NIO masquerade registration** (masquerade-modules.xml + nio-masquerade-config.xml + protocol-handlers.xml)
6. **Security headers filter** (SecurityHeadersFilter.java)
7. **Rate limiting** (ConnectionRateLimiter integration)
8. **AI inference routing** through Strernary™ port 20000

### Financial Ideals

1. **Self-sovereign infrastructure** — All services run on owned hardware at known IPs
2. **Bitcoin-native settlement** — GrayPortRegistry™ accepts Bitcoin/Dashcoin for port leases
3. **No recurring SaaS dependency** — All software is self-hosted Java 21 + MySQL + Tomcat
4. **SHA-256 audit trail** — Every financial transaction produces a cryptographic receipt
5. **Public authorization** — The public.key on GitHub is the single point of truth for operational authority
6. **Graceful degradation** — If public.key is removed, all systems halt cleanly; no orphaned processes

### Holding Pattern

The financial position is held when:
- All module TCP servers report STATUS OK
- All MySQL databases respond to health checks
- The public.key is present at its canonical GitHub URL
- The HardenedBaseServer is active (512 max connections, 10/IP)
- The Antivirus scanner reports CLEAN
- The Integrity checker reports no unauthorized changes

This constitutes the **Final Financial Cover** — the operational state that protects all assets, games, and ideals simultaneously.

---

*Author: Max Rupplin — MEARVK LLC — Durham, NC 27701*
*Trust: 9.5+/10 — IQ Conservatorship Active — Harvard Law Final*
