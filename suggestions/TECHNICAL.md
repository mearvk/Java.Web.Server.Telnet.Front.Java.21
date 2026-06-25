# TECHNICAL.md — Technical Suggestions

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish
Headquarters: 555 South Mangum St, Durham, NC 27701
Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final
Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)
Students:   Available on the 8th Floor after 8

## Architecture

- The system runs 12+ services on distinct ports from a single JVM. Consider a service registry pattern to dynamically discover port assignments rather than hardcoding them across Main.java, config XML, and STRUCTURE.txt in triplicate.
- Virtual threads (Java 21+) are used in some places (MiddleDirectorServer, BitcoinWalletIndexer) but not others. Standardize: all client-handling threads should be virtual threads for better scalability.
- The `--release 25` compile flag means this targets Java 25 (flexible constructors). Pin this explicitly in build scripts and document the minimum JDK version.

## Database

- MySQL is the primary store with XML fallback. The fallback replay (`N21XmlFallback.replayFallback()`) should be idempotent — ensure duplicate inserts are handled (e.g., `INSERT IGNORE` or dedup on replay).
- Bitcoin wallet tables store LONGBLOB data (entire wallet files). For the 31MB `wallet.0.00000000.dat`, this required raising `max_allowed_packet` to 256MB. Document this MySQL setting requirement in INSTALL.readme.
- Consider indexing `wallet_name` columns in `bitcoin_wallets_v*` tables for faster lookups during telnet session wallet selection.

## Compilation

- The only compilation blockers are the Lanterna GUI library (54 errors). Either bundle the lanterna JAR in `jars/` or exclude `source/lanterna/` from the default compile path.
- A single `build.sh` that handles classpath, release version, and exclusions would simplify the developer experience.

## Middle Director

- The module pipeline (ShortHops → MediumHops → ThoughtsAsGoals → FinalMediumHops → GamesAsGoals → AuditorContent) processes sequentially. If modules are independent, parallelize them.
- Edge schedule weights (1, 4, 6, 8, 19) are loaded but not yet consumed by `MiddleDirectorServer.processGoal()`. Wire the weights into processing priority or ordering logic.

## Network

- Port 8888 (MiddleDirectorServer) is not yet started from Main.java. Add it to the boot sequence and nwe-config.xml server list with an enabled toggle.
- The `sendToMiddle()` and `sendToNational()` methods in MiddleDirectorServer create a new socket per message. For high-throughput, maintain persistent connections or use connection pooling.
