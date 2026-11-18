#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NWE.ubuntu-install.sh — NitroWebExpress (JWSTF) installer for Ubuntu servers
# that may already host Apache2 and/or Tomcat sites.
#
# Two deployment shapes, selectable together or apart:
#
#   metal    The telnet/TCP server platform (Main) as a systemd service
#            "jwstf", run as its own system user from /opt/jwstf, with config,
#            state and logs in /etc, /var/lib and /var/log (the layout from
#            config/preferred-install-paths.json).
#
#   webapp   The JSP/servlet module frontends (modules/*/servlets) as WARs in
#            an EXISTING Tomcat, plus an Apache2 reverse-proxy snippet.
#
# "Sensitive to existing installs" means, concretely:
#   * Nothing is installed or replaced unless you pass --install-deps.
#   * Existing Tomcat (apt tomcat9/10/11, /opt/*tomcat*, running process) and
#     Apache2 are detected and used as-is. If several Tomcats are found, the
#     script stops and asks which one (--tomcat-base).
#   * A webapp context that already exists in Tomcat, or a URL path already
#     claimed in Apache (ProxyPass/Alias/Location, or a directory under a
#     DocumentRoot), is SKIPPED and reported. Only contexts recorded in this
#     script's own manifest are ever upgraded or removed.
#   * Existing Apache vhosts are never edited. One new file is added
#     (conf-available/jwstf-proxy.conf), validated with apache2ctl configtest,
#     and rolled back if the test fails. Apache is reloaded, never restarted.
#   * Tomcat is not restarted unless you pass --restart-tomcat.
#   * Existing listening ports are checked before the service is installed.
#   * Local edits to /etc/jwstf and data under /var/lib/jwstf survive upgrades.
#   * Java: the compiled classes in out/ are class-file version 69 (JDK 25).
#     A JDK 25+ is located (or installed with --install-deps) and referenced
#     by absolute path in the unit; update-alternatives is never touched.
#
# Usage:
#   sudo bash bash/NWE.ubuntu-install.sh plan      [options]   read-only report
#   sudo bash bash/NWE.ubuntu-install.sh install   [options]
#   sudo bash bash/NWE.ubuntu-install.sh status
#   sudo bash bash/NWE.ubuntu-install.sh uninstall [--purge]
#
# Options:
#   --mode metal|webapp|both     what to install                  (default: both)
#   --prefix DIR                 application dir        (default: /opt/jwstf)
#   --user NAME                  service account        (default: jwstf)
#   --java-home DIR              JDK 25+ to run the service with
#   --tomcat-base DIR            CATALINA_BASE to deploy into (skips autodetect)
#   --tomcat-home DIR            CATALINA_HOME (needed for manual layouts only
#                                if it differs from the base)
#   --tomcat-service NAME        systemd unit of that Tomcat (for restart)
#   --modules a,b,c              only these contexts            (default: all)
#   --context-prefix STR         prefix every context, e.g. "nwe-" so that
#                                /chat becomes /nwe-chat
#   --no-apache                  deploy WARs, do not touch Apache
#   --restart-tomcat             restart Tomcat if it cannot hot-deploy
#   --no-start                   metal: install the unit but do not start it
#   --ignore-port-conflicts      metal: continue even if a port is taken
#   --rebuild                    metal: compile from source with JDK 25 and install
#                                that, even if a local out/ exists (done automatically
#                                when out/Main.class is missing)
#   --grant-apache-root          metal: if the <apache-root> dir from nwe-config.xml
#                                already exists and the service user cannot write
#                                to it, add an ACL for that user on that one dir
#   --install-deps               apt-get install missing Java 25 / Tomcat 10 /
#                                Apache2 (default: report only)
#   --dry-run                    print actions, change nothing (same as `plan`)
#   --purge                      uninstall: also delete config, state and logs
#
# Not handled here (use the existing scripts): MySQL setup (bash/MySQL.setup.sh),
# per-module databases (modules/*/servlets/setup-db.sh), ClamAV, firewall.
# ─────────────────────────────────────────────────────────────────────────────

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JAVA_MIN=25                    # out/*.class are version 69; pom.xml targets 25

# ── defaults ────────────────────────────────────────────────────────────────
CMD=""
MODE="both"
PREFIX="/opt/jwstf"
SVC_USER="jwstf"
CONF_DIR="${JWSTF_CONF_DIR:-/etc/jwstf}"        # the three dirs are overridable for testing
STATE_DIR="${JWSTF_STATE_DIR:-/var/lib/jwstf}"
LOG_DIR="${JWSTF_LOG_DIR:-/var/log/jwstf}"
UNIT_NAME="jwstf"
APACHE_CONF_NAME="jwstf-proxy"
JAVA_HOME_ARG=""
TOMCAT_BASE_ARG=""
TOMCAT_HOME_ARG=""
TOMCAT_SERVICE_ARG=""
ONLY_MODULES=""
CTX_PREFIX=""
NO_APACHE=0
RESTART_TOMCAT=0
NO_START=0
IGNORE_PORTS=0
REBUILD=0
GRANT_APACHE_ROOT=0
INSTALL_DEPS=0
DRY_RUN=0
PURGE=0

# relative module dir : default context   (same map as deploy-all-modules.sh,
# plus the two nested modules)
MODULE_MAP=(
    "AE6E66:ae6e66"
    "analytics:analytics"
    "armorer:armorer"
    "bitcoin:bitcoin"
    "black-belt:blackbelt"
    "black/presidential/Brarner.M.Alete:brarner.m.alete"
    "calendar:calendar"
    "chat:chat"
    "cia:california-cia"
    "Defined:defined"
    "dictionary:dictionary"
    "duke:california-duke"
    "emeter:emeter"
    "fbi:california-fbi"
    "fiduciary:fiduciary"
    "gray:gray-registry"
    "gray.a85:gray85-registry"
    "languages:languages"
    "library:library"
    "ncsu:california-ncsu"
    "nsa:california-nsa"
    "red/Futures:futures"
    "spectrum-tandem:spectrum-tandem"
    "tandem-equals:tandem-equals"
    "unc:california-unc"
    "uncw:uncw"
    "vietnam:vietnam"
)

# ── output helpers ──────────────────────────────────────────────────────────
if [[ -t 1 ]]; then C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_B=$'\e[1m'; C_0=$'\e[0m'
else C_G=""; C_Y=""; C_R=""; C_B=""; C_0=""; fi
N_WARN=0
step() { printf '\n%s== %s ==%s\n' "$C_B" "$*" "$C_0"; }
info() { printf '   %s\n' "$*"; }
ok()   { printf '   %s[ok]%s   %s\n' "$C_G" "$C_0" "$*"; }
skip() { printf '   %s[skip]%s %s\n' "$C_Y" "$C_0" "$*"; }
warn() { printf '   %s[warn]%s %s\n' "$C_Y" "$C_0" "$*" >&2; N_WARN=$((N_WARN + 1)); }
die()  { printf '%s[fail]%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }
dry()  { printf '   [dry-run] %s\n' "$*"; }

# run CMD…: execute, or just print in dry-run mode
run() {
    if [[ $DRY_RUN -eq 1 ]]; then dry "$*"; return 0; fi
    "$@"
}

TMP=""
NEW_DIR=""
cleanup() { [[ -n "$TMP" && -d "$TMP" ]] && rm -rf "$TMP"; [[ -n "$NEW_DIR" && -d "$NEW_DIR" ]] && rm -rf "$NEW_DIR"; return 0; }
trap cleanup EXIT
trap 'printf "%s[fail]%s line %s: %s\n" "$C_R" "$C_0" "$LINENO" "$BASH_COMMAND" >&2' ERR

usage() { sed -n '2,/^# Not handled here/p' "$0" | sed 's/^# \{0,1\}//'; }

# ── argument parsing ────────────────────────────────────────────────────────
[[ $# -gt 0 ]] || { CMD="plan"; }
while [[ $# -gt 0 ]]; do
    case "$1" in
        plan|install|uninstall|status|help) CMD="$1" ;;
        --mode)               MODE="${2:?--mode needs a value}"; shift ;;
        --prefix)             PREFIX="${2:?}"; shift ;;
        --user)               SVC_USER="${2:?}"; shift ;;
        --java-home)          JAVA_HOME_ARG="${2:?}"; shift ;;
        --tomcat-base)        TOMCAT_BASE_ARG="${2:?}"; shift ;;
        --tomcat-home)        TOMCAT_HOME_ARG="${2:?}"; shift ;;
        --tomcat-service)     TOMCAT_SERVICE_ARG="${2:?}"; shift ;;
        --modules)            ONLY_MODULES="${2:?}"; shift ;;
        --context-prefix)     CTX_PREFIX="${2:?}"; shift ;;
        --no-apache)          NO_APACHE=1 ;;
        --restart-tomcat)     RESTART_TOMCAT=1 ;;
        --no-start)           NO_START=1 ;;
        --ignore-port-conflicts) IGNORE_PORTS=1 ;;
        --rebuild)            REBUILD=1 ;;
        --grant-apache-root)  GRANT_APACHE_ROOT=1 ;;
        --install-deps)       INSTALL_DEPS=1 ;;
        --dry-run)            DRY_RUN=1 ;;
        --purge)              PURGE=1 ;;
        -h|--help)            CMD="help" ;;
        *) die "Unknown argument: $1 (try: $SCRIPT_NAME help)" ;;
    esac
    shift
done
CMD="${CMD:-plan}"
[[ "$CMD" == "plan" ]] && DRY_RUN=1
[[ "$CMD" == "help" ]] && { usage; exit 0; }
case "$MODE" in metal|webapp|both) ;; *) die "--mode must be metal, webapp or both" ;; esac
[[ "$SVC_USER" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] || die "--user must be a plain lowercase account name"
[[ "$CTX_PREFIX" =~ ^[A-Za-z0-9._-]*$ ]] || die "--context-prefix may contain only letters, digits, . _ -"
[[ "$PREFIX" == /* ]] || die "--prefix must be an absolute path"
case "$PREFIX" in /|/usr|/usr/*|/etc|/etc/*|/var|/var/*|/bin|/sbin|/lib|/boot|/home|/root)
    [[ "$PREFIX" == "/usr/local/jwstf" ]] || die "Refusing --prefix $PREFIX (system path). Use /opt/jwstf or similar." ;;
esac

MANIFEST="$STATE_DIR/install-manifest"
UNIT_FILE="${JWSTF_UNIT_DIR:-/etc/systemd/system}/$UNIT_NAME.service"
UNIT_MARK="# Managed by $SCRIPT_NAME"
APACHE_ETC="${APACHE_ETC:-/etc/apache2}"          # overridable for testing
APACHE_CONF_FILE="$APACHE_ETC/conf-available/$APACHE_CONF_NAME.conf"
APACHE_CONF_MARK="# Managed by $SCRIPT_NAME"

want_metal()  { [[ "$MODE" == metal  || "$MODE" == both ]]; }
want_webapp() { [[ "$MODE" == webapp || "$MODE" == both ]]; }

need_root() {
    [[ $DRY_RUN -eq 1 || $EUID -eq 0 ]] || die "Run as root (sudo bash $0 $CMD …). Use 'plan' for a read-only report."
}

# ── manifest (key=value, parsed, never sourced) ─────────────────────────────
mf_values() { [[ -r "$MANIFEST" ]] && sed -n "s/^$1=//p" "$MANIFEST" || true; }
mf_first()  { mf_values "$1" | head -1 || true; }
mf_has()    { mf_values "$1" | grep -xF -- "$2" >/dev/null; }

# ── small detection utilities ───────────────────────────────────────────────
java_major() {   # $1 = path to java binary
    "$1" -version 2>&1 | sed -n '1s/.*version "\([0-9]*\).*/\1/p'
}

find_java() {    # prints JAVA_HOME of the first JDK >= JAVA_MIN, else nothing
    local cands=() h j
    [[ -n "$JAVA_HOME_ARG" ]] && cands+=("$JAVA_HOME_ARG")
    [[ -n "${JAVA_HOME:-}" ]] && cands+=("$JAVA_HOME")
    if j="$(command -v java 2>/dev/null)"; then cands+=("$(dirname "$(dirname "$(readlink -f "$j")")")"); fi
    for h in /usr/lib/jvm/*; do [[ -d "$h" ]] && cands+=("$h"); done
    for h in "${cands[@]}"; do
        [[ -x "$h/bin/java" && -x "$h/bin/javac" ]] || continue
        local m; m="$(java_major "$h/bin/java" || true)"
        if [[ "$m" =~ ^[0-9]+$ && "$m" -ge $JAVA_MIN ]]; then printf '%s\n' "$h"; return 0; fi
    done
    return 1
}

apt_install() {
    [[ $INSTALL_DEPS -eq 1 ]] || return 1
    command -v apt-get >/dev/null || die "apt-get not found; install $* yourself."
    if [[ $DRY_RUN -eq 1 ]]; then dry "apt-get install -y --no-install-recommends $*"; return 0; fi
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# ── Tomcat discovery ────────────────────────────────────────────────────────
# Parallel arrays: TC_BASE TC_HOME TC_SVC TC_KIND
TC_BASE=(); TC_HOME=(); TC_SVC=(); TC_KIND=()

tc_add() {   # base home svc kind
    local b h
    b="$(readlink -f "$1" 2>/dev/null || echo "$1")"; h="$(readlink -f "$2" 2>/dev/null || echo "$2")"
    local i
    for i in "${!TC_BASE[@]}"; do [[ "${TC_BASE[$i]}" == "$b" ]] && return 0; done
    [[ -d "$b/webapps" ]] || return 0
    TC_BASE+=("$b"); TC_HOME+=("$h"); TC_SVC+=("$3"); TC_KIND+=("$4")
}

tc_unit_for() {   # find a systemd unit that references this Tomcat home/base
    command -v systemctl >/dev/null || return 0
    local u
    while read -r u _; do
        [[ -n "$u" ]] || continue
        if systemctl cat "$u" 2>/dev/null | grep -F -e "$1" ${2:+-e "$2"} >/dev/null; then echo "${u%.service}"; return 0; fi
    done < <(systemctl list-unit-files --no-legend --type=service '*tomcat*' 2>/dev/null)
    return 0
}

discover_tomcat() {
    local v d
    for v in 11 10 9; do      # distribution packages keep their own layout
        if dpkg -s "tomcat$v" >/dev/null 2>&1; then
            tc_add "/var/lib/tomcat$v" "/usr/share/tomcat$v" "tomcat$v" "apt tomcat$v"
        fi
    done
    local manual=(/opt/tomcat /opt/apache-tomcat-* /usr/local/tomcat /usr/local/apache-tomcat-* /srv/tomcat* "${CATALINA_HOME:-}")
    for d in "${manual[@]}"; do
        [[ -n "$d" && -x "$d/bin/catalina.sh" ]] && tc_add "$d" "$d" "$(tc_unit_for "$d")" "manual"
    done
    # running JVMs: -Dcatalina.base / -Dcatalina.home
    local line b h
    while IFS= read -r line; do
        b="$(grep -oP '(?<=-Dcatalina\.base=)\S+' <<<"$line" || true)"
        h="$(grep -oP '(?<=-Dcatalina\.home=)\S+' <<<"$line" || true)"
        [[ -n "$b" ]] && tc_add "$b" "${h:-$b}" "$(tc_unit_for "$b" "$h")" "running"
    done < <(ps -eo args 2>/dev/null | grep -F 'catalina' | grep -v grep || true)
}

# Selected Tomcat (filled by select_tomcat)
TOMCAT_BASE=""; TOMCAT_HOME=""; TOMCAT_SVC=""; TOMCAT_KIND=""
TOMCAT_PORT="8080"; TOMCAT_APPBASE=""; TOMCAT_AUTODEPLOY="true"; TOMCAT_JAKARTA=1
TOMCAT_SERVLET_API=""; TOMCAT_JAVA_RELEASE=17

select_tomcat() {
    step "Tomcat"
    if [[ -n "$TOMCAT_BASE_ARG" ]]; then
        [[ -d "$TOMCAT_BASE_ARG/webapps" ]] || die "--tomcat-base $TOMCAT_BASE_ARG has no webapps/ directory"
        TC_BASE=(); TC_HOME=(); TC_SVC=(); TC_KIND=()
        tc_add "$TOMCAT_BASE_ARG" "${TOMCAT_HOME_ARG:-$TOMCAT_BASE_ARG}" "$TOMCAT_SERVICE_ARG" "given"
    else
        discover_tomcat
    fi
    local n=${#TC_BASE[@]} i
    if [[ $n -eq 0 && $INSTALL_DEPS -eq 1 ]]; then
        info "No Tomcat found; installing distribution package tomcat10 (--install-deps)."
        apt_install tomcat10
        [[ $DRY_RUN -eq 1 ]] && { skip "Tomcat would be installed; webapp steps are shown after it exists."; return 1; }
        discover_tomcat; n=${#TC_BASE[@]}
    fi
    if [[ $n -eq 0 ]]; then
        warn "No Tomcat found. Pass --tomcat-base DIR, or --install-deps to install tomcat10."
        return 1
    fi
    if [[ $n -gt 1 ]]; then
        info "Several Tomcat installs found:"
        for i in "${!TC_BASE[@]}"; do info "  - ${TC_BASE[$i]}  (${TC_KIND[$i]}, service: ${TC_SVC[$i]:-unknown})"; done
        die "Refusing to guess. Re-run with --tomcat-base DIR."
    fi
    TOMCAT_BASE="${TC_BASE[0]}"; TOMCAT_HOME="${TOMCAT_HOME_ARG:-${TC_HOME[0]}}"
    TOMCAT_SVC="${TOMCAT_SERVICE_ARG:-${TC_SVC[0]}}"; TOMCAT_KIND="${TC_KIND[0]}"
    ok "Using $TOMCAT_BASE  ($TOMCAT_KIND, service: ${TOMCAT_SVC:-none found})"

    # server.xml → HTTP port, appBase, autoDeploy
    local sx="$TOMCAT_BASE/conf/server.xml" out
    TOMCAT_APPBASE="webapps"
    if [[ -r "$sx" ]] && command -v python3 >/dev/null; then
        out="$(python3 - "$sx" <<'PY' 2>/dev/null || true
import sys, xml.etree.ElementTree as ET
r = ET.parse(sys.argv[1]).getroot()
port = "8080"
for c in r.iter("Connector"):
    p = c.get("protocol", "HTTP/1.1")
    if p.startswith("HTTP") and c.get("SSLEnabled", "false") != "true" and c.get("port"):
        port = c.get("port"); break
h = next(r.iter("Host"), None)
print(port, (h.get("appBase", "webapps") if h is not None else "webapps"),
      (h.get("autoDeploy", "true") if h is not None else "true"))
PY
)"
        if [[ -n "$out" ]]; then read -r TOMCAT_PORT TOMCAT_APPBASE TOMCAT_AUTODEPLOY <<<"$out"; fi
    else
        warn "Cannot parse $sx (missing or no python3); assuming port 8080, appBase webapps."
    fi
    [[ "$TOMCAT_PORT" =~ ^[0-9]+$ ]] || { warn "Connector port is a property ($TOMCAT_PORT); assuming 8080."; TOMCAT_PORT=8080; }
    [[ "$TOMCAT_APPBASE" == /* ]] || TOMCAT_APPBASE="$TOMCAT_BASE/$TOMCAT_APPBASE"
    [[ -d "$TOMCAT_APPBASE" ]] || die "Tomcat appBase $TOMCAT_APPBASE does not exist"
    info "HTTP connector: 127.0.0.1:$TOMCAT_PORT   appBase: $TOMCAT_APPBASE   autoDeploy: $TOMCAT_AUTODEPLOY"

    # Jakarta (Tomcat 10+) vs javax (Tomcat 9): the modules use jakarta.servlet
    local api=""
    for i in "$TOMCAT_HOME/lib/servlet-api.jar" "$TOMCAT_BASE/lib/servlet-api.jar" "$TOMCAT_HOME/lib/jakarta.servlet-api.jar"; do [[ -f "$i" ]] && { api="$i"; break; }; done
    if [[ -n "$api" ]] && command -v unzip >/dev/null; then
        unzip -l "$api" 2>/dev/null | grep 'jakarta/servlet/Servlet.class' >/dev/null && TOMCAT_JAKARTA=1 || TOMCAT_JAKARTA=0
    elif [[ "$TOMCAT_KIND" == "apt tomcat9" || "$TOMCAT_HOME" == *tomcat9* || "$TOMCAT_HOME" == *-9.* ]]; then
        TOMCAT_JAKARTA=0
    fi
    TOMCAT_SERVLET_API="$api"
    if [[ $TOMCAT_JAKARTA -eq 0 ]]; then
        warn "This Tomcat uses the javax.* namespace (Tomcat 9). The modules need Tomcat 10+ (jakarta.*); webapp deploy skipped."
        return 1
    fi
    # Compile servlet sources for the JVM Tomcat runs on, not for our JDK 25
    local tj; tj="$(command -v java 2>/dev/null || true)"
    if [[ -n "$tj" ]]; then
        local m; m="$(java_major "$tj" || true)"
        [[ "$m" =~ ^[0-9]+$ && "$m" -ge 11 ]] && TOMCAT_JAVA_RELEASE="$m"
    fi
    return 0
}

# ── Apache discovery ────────────────────────────────────────────────────────
APACHE_PRESENT=0; APACHE_ACTIVE=0; APACHE_DOCROOTS=""
discover_apache() {
    step "Apache2"
    if ! command -v apache2ctl >/dev/null 2>&1 && ! command -v apache2 >/dev/null 2>&1; then
        if [[ $INSTALL_DEPS -eq 1 ]]; then apt_install apache2; [[ $DRY_RUN -eq 1 ]] && { skip "Apache2 would be installed."; return 1; }
        else skip "Apache2 not installed; skipping proxy setup (--install-deps to install)."; return 1; fi
    fi
    [[ -d "$APACHE_ETC" ]] || { skip "No $APACHE_ETC (not a Debian/Ubuntu Apache layout); skipping proxy setup."; return 1; }
    APACHE_PRESENT=1
    systemctl is-active --quiet apache2 2>/dev/null && APACHE_ACTIVE=1
    ok "Apache2 found (service active: $([[ $APACHE_ACTIVE -eq 1 ]] && echo yes || echo no))"
    APACHE_DOCROOTS="$(grep -RhiE '^\s*DocumentRoot' "$APACHE_ETC/sites-enabled" "$APACHE_ETC/apache2.conf" "$APACHE_ETC/conf-enabled" 2>/dev/null \
        | awk '{gsub(/"/,"",$2); print $2}' | sort -u | tr '\n' ' ')"
    [[ -n "$APACHE_DOCROOTS" ]] || APACHE_DOCROOTS="/var/www/html"
    info "Existing DocumentRoot(s): $APACHE_DOCROOTS"
    return 0
}

apache_path_taken() {   # $1 = context; prints reason and returns 0 if the URL path is already in use
    local ctx="$1" f d hit
    hit="$(grep -RHnEi --exclude="$APACHE_CONF_NAME.conf" "^\s*(ProxyPass|ProxyPassMatch|Alias|AliasMatch|ScriptAlias|RedirectMatch|Redirect|<Location|<LocationMatch)\s+\"?\^?/?${ctx//./\\.}(/|\"|\\$|\s|>|\))" \
        "$APACHE_ETC/sites-enabled" "$APACHE_ETC/conf-enabled" "$APACHE_ETC/apache2.conf" 2>/dev/null \
        | head -1 || true)"
    [[ -n "$hit" ]] && { echo "Apache config already maps /$ctx ($hit)"; return 0; }
    for d in $APACHE_DOCROOTS; do
        [[ -e "$d/$ctx" ]] && { echo "$d/$ctx exists and would be shadowed by the proxy"; return 0; }
    done
    return 1
}

# ── Java ────────────────────────────────────────────────────────────────────
JAVA_HOME_USE=""
ensure_java() {
    step "Java $JAVA_MIN+"
    if JAVA_HOME_USE="$(find_java)"; then
        ok "Using $JAVA_HOME_USE ($("$JAVA_HOME_USE/bin/java" -version 2>&1 | head -1))"
        return 0
    fi
    local pkg="openjdk-$JAVA_MIN-jdk-headless"
    if [[ $INSTALL_DEPS -eq 1 ]]; then
        if command -v apt-cache >/dev/null && apt-cache policy "$pkg" 2>/dev/null | grep 'Candidate: [^(]' >/dev/null; then
            apt_install "$pkg"
            [[ $DRY_RUN -eq 1 ]] && { JAVA_HOME_USE="/usr/lib/jvm/java-$JAVA_MIN-openjdk-amd64"; return 0; }
            JAVA_HOME_USE="$(find_java)" || die "Installed $pkg but could not locate it under /usr/lib/jvm."
            return 0
        fi
        die "No $pkg candidate in your apt sources. On Ubuntu 22.04/24.04 it lives in 'universe' (sudo add-apt-repository universe && sudo apt-get update). Otherwise install a JDK $JAVA_MIN+ (e.g. Temurin) and pass --java-home DIR."
    fi
    if [[ $DRY_RUN -eq 1 ]]; then warn "No JDK $JAVA_MIN+ found (needed by the metal service). Pass --java-home DIR or --install-deps."; JAVA_HOME_USE=""; return 0; fi
    die "No JDK $JAVA_MIN+ found. The compiled classes are Java $JAVA_MIN bytecode. Pass --java-home DIR or --install-deps."
}

# Point the app's own <web-servers><tomcat> block at the Tomcat we found, but
# only while it still holds the shipped defaults (a local edit always wins).
sync_tomcat_config() {
    local cfg="$CONF_DIR/configuration/nwe-config.xml"
    [[ $DRY_RUN -eq 1 ]] && { dry "set <tomcat><install-dir>=$TOMCAT_HOME and <service-name>=${TOMCAT_SVC:-unchanged} in $cfg if still at shipped defaults"; return 0; }
    [[ -f "$cfg" ]] || { info "No $cfg yet (metal not installed here); app Tomcat settings unchanged."; return 0; }
    command -v python3 >/dev/null || { warn "python3 missing; set <web-servers><tomcat><install-dir> in $cfg to $TOMCAT_HOME yourself."; return 0; }
    python3 - "$cfg" "$TOMCAT_HOME" "$TOMCAT_SVC" <<'PY' && ok "App config now points at Tomcat $TOMCAT_HOME" || true
import re, sys
path, home, svc = sys.argv[1:4]
txt = open(path, encoding="utf-8").read()
m = re.search(r"(<tomcat>)(.*?)(</tomcat>)", txt, re.S)
if not m:
    sys.exit(1)
blk = m.group(2)
changed = False
if "<install-dir>/opt/apache-tomcat-11.0.2</install-dir>" in blk and home != "/opt/apache-tomcat-11.0.2":
    blk = blk.replace("<install-dir>/opt/apache-tomcat-11.0.2</install-dir>", "<install-dir>%s</install-dir>" % home); changed = True
if svc and "<service-name>tomcat</service-name>" in blk and svc != "tomcat":
    blk = blk.replace("<service-name>tomcat</service-name>", "<service-name>%s</service-name>" % svc); changed = True
if not changed:
    sys.exit(1)
open(path, "w", encoding="utf-8").write(txt[:m.start(2)] + blk + txt[m.end(2):])
PY
}

# ── port check (metal) ──────────────────────────────────────────────────────
nwe_ports() {
    local cfg="$REPO_ROOT/configuration/nwe-config.xml" out=""
    [[ -r "$cfg" ]] || return 0
    # Strict parse first (honours <enabled>). The shipped nwe-config.xml is not
    # well-formed XML today (a "--" inside a comment near line 982), so fall
    # back to a plain scan of <port> tags rather than checking nothing.
    if command -v python3 >/dev/null; then
        out="$(python3 - "$cfg" <<'PY' 2>/dev/null
import sys, xml.etree.ElementTree as ET
for e in ET.parse(sys.argv[1]).getroot().iter():
    p, en = e.find("port"), e.find("enabled")
    if p is not None and p.text and p.text.strip().isdigit() and (en is None or (en.text or "").strip().lower() == "true"):
        print(p.text.strip())
PY
)" || out=""
    fi
    [[ -n "$out" ]] || out="$(grep -oP '(?<=<port>)\d+(?=</port>)' "$cfg" || true)"
    [[ -n "$out" ]] && sort -un <<<"$out" | grep -vx 0
    return 0
}

check_ports() {
    step "Port check (metal)"
    if systemctl is-active --quiet "$UNIT_NAME" 2>/dev/null; then
        skip "$UNIT_NAME is already running (upgrade); its own ports are expected to be in use."; return 0
    fi
    command -v ss >/dev/null || { warn "ss not found; cannot check ports."; return 0; }
    local listening p taken=()
    listening="$(ss -Hltn 2>/dev/null | awk '{print $4}' | sed 's/.*://' | sort -u)"
    while read -r p; do
        [[ -n "$p" ]] && grep -qx "$p" <<<"$listening" && taken+=("$p")
    done < <(nwe_ports)
    if [[ ${#taken[@]} -eq 0 ]]; then ok "All enabled NWE ports are free."; return 0; fi
    info "Already listening: ${taken[*]}"
    if [[ $IGNORE_PORTS -eq 1 ]]; then warn "Continuing because of --ignore-port-conflicts."; return 0; fi
    if [[ $DRY_RUN -eq 1 ]]; then warn "Port conflict(s): ${taken[*]} (install would stop here)."; return 0; fi
    die "Ports in use by something else: ${taken[*]}. Free them, disable those services in configuration/nwe-config.xml, or pass --ignore-port-conflicts."
}

# ── metal install ───────────────────────────────────────────────────────────
install_metal() {
    step "Metal install → $PREFIX"
    if [[ ! -f "$REPO_ROOT/out/Main.class" && $REBUILD -eq 0 ]]; then
        info "No compiled classes in $REPO_ROOT/out (the repo no longer tracks them); building from source."
        REBUILD=1
    fi
    [[ -n "$JAVA_HOME_USE" || $DRY_RUN -eq 1 ]] || die "No JDK available."

    if [[ -e "$UNIT_FILE" ]] && ! grep -qF "$UNIT_MARK" "$UNIT_FILE"; then
        die "$UNIT_FILE exists and was not created by this script. Not overwriting; choose another name by editing UNIT_NAME or remove it."
    fi

    # service account
    if id "$SVC_USER" >/dev/null 2>&1; then
        skip "User '$SVC_USER' exists; reusing."
    else
        run useradd --system --user-group --home-dir "$STATE_DIR" --no-create-home --shell /usr/sbin/nologin "$SVC_USER"
        ok "Created system user '$SVC_USER'"
    fi

    TMP="${TMP:-$(mktemp -d)}"
    local new="$PREFIX.new.$$"; NEW_DIR="$new"

    if [[ $REBUILD -eq 1 ]]; then rebuild_classes; fi

    # application tree (code + jars only; mutable data is linked in below)
    info "Staging application files…"
    if [[ $DRY_RUN -eq 1 ]]; then dry "copy out/ jars/ scripts/ bash/ modules/ resources/ languages/ config/ training/ math/ downloads/ → $new"
    else
        rm -rf "$new"; mkdir -p "$new"
        local items=(scripts bash resources languages config modules training math downloads
                     jars/mysql/mysql-connector-j-9.7.0.jar jars/lanterna-3.1.5.jar)
        [[ -d "$REPO_ROOT/jars/djl"   ]] && items+=(jars/djl)
        [[ -d "$REPO_ROOT/jars/jpcap" ]] && items+=(jars/jpcap)
        local present=() it
        [[ -z "$REBUILT_OUT" ]] && items+=(out)
        for it in "${items[@]}"; do [[ -e "$REPO_ROOT/$it" ]] && present+=("$it") || warn "Not in checkout, skipped: $it"; done
        tar -C "$REPO_ROOT" \
            --exclude='modules/*/servlets' --exclude='modules/*/source' \
            -cf - "${present[@]}" | tar -C "$new" -xf -
        if [[ -n "$REBUILT_OUT" ]]; then rm -rf "$new/out"; cp -a "$REBUILT_OUT" "$new/out"; fi
    fi

    # mutable state lives outside the app tree
    setup_state_dirs
    if [[ $DRY_RUN -eq 0 ]]; then
        local d
        for d in configuration:"$CONF_DIR/configuration" authentication:"$CONF_DIR/authentication" \
                 logging:"$LOG_DIR" data:"$STATE_DIR/data" database:"$STATE_DIR/database"; do
            ln -s "${d#*:}" "$new/${d%%:*}"
        done
        # Chat/Emeter read ./.nwe-credentials from the working directory
        ln -s "$CONF_DIR/nwe-credentials" "$new/.nwe-credentials"
    else
        dry "symlink configuration, authentication, logging, data, database, .nwe-credentials → /etc|/var/lib|/var/log/jwstf"
    fi

    # classpath (absolute, systemd does not expand globs)
    local cp="$PREFIX/out" j
    if [[ $DRY_RUN -eq 0 ]]; then
        while IFS= read -r j; do cp+=":$PREFIX/${j#"$new"/}"; done < <(
            { echo "$new/jars/mysql/mysql-connector-j-9.7.0.jar"
              find "$new/jars/djl" "$new/jars/jpcap" -name '*.jar' 2>/dev/null | sort
              echo "$new/jars/lanterna-3.1.5.jar"; } | while read -r f; do [[ -f "$f" ]] && echo "$f"; done)
    fi

    # unit file
    local unit="$TMP/$UNIT_NAME.service"
    cat > "$unit" <<EOF
$UNIT_MARK — edit via the script or a drop-in (systemctl edit $UNIT_NAME), not in place.
[Unit]
Description=NitroWebExpress (JWSTF) telnet/TCP server platform
After=network-online.target mysql.service mariadb.service
Wants=network-online.target

[Service]
Type=simple
User=$SVC_USER
Group=$SVC_USER
WorkingDirectory=$PREFIX
ExecStart=${JAVA_HOME_USE:-/usr/bin}/bin/java -Dnwe.root=$PREFIX -Xms512m -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:G1HeapRegionSize=16m -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -cp $cp Main
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
# the app writes relative to its working directory; code and libraries stay read-only
ReadOnlyPaths=$PREFIX/out $PREFIX/jars
ReadWritePaths=$PREFIX $STATE_DIR $LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
    info "Unit file → $UNIT_FILE"

    local was_active=0
    systemctl is-active --quiet "$UNIT_NAME" 2>/dev/null && was_active=1
    if [[ $DRY_RUN -eq 1 ]]; then
        dry "stop $UNIT_NAME if running; swap $PREFIX (old kept as $PREFIX.prev); install unit; systemctl daemon-reload; enable$([[ $NO_START -eq 0 ]] && echo ' + start')"
        return 0
    fi
    [[ $was_active -eq 1 ]] && systemctl stop "$UNIT_NAME"
    if [[ -e "$PREFIX" ]]; then rm -rf "$PREFIX.prev"; mv "$PREFIX" "$PREFIX.prev"; fi
    # runtime output written under the app dir survives an upgrade (no-clobber:
    # freshly shipped files win, generated files are kept)
    if [[ -d "$PREFIX.prev" ]]; then
        local rp
        for rp in nwe-files exception.log models reports lockouts training math downloads \
                  modules/AE6E66/portraits modules/AE6E66/marrister modules/AE6E66/sent modules/AE6E66/personal; do
            [[ -e "$PREFIX.prev/$rp" ]] || continue
            mkdir -p "$new/$(dirname "$rp")"
            cp -an "$PREFIX.prev/$rp" "$new/$(dirname "$rp")/" 2>/dev/null || true
        done
    fi
    mv "$new" "$PREFIX"; NEW_DIR=""
    # Service user owns the tree (the app writes next to its code); the compiled
    # classes and libraries stay root-owned and are also mounted read-only.
    chown -hR "$SVC_USER:$SVC_USER" "$PREFIX"
    chown -hR root:root "$PREFIX/out" "$PREFIX/jars"
    chmod -R go-w "$PREFIX/out" "$PREFIX/jars"
    install -m 0644 "$unit" "$UNIT_FILE"
    systemctl daemon-reload
    systemctl enable "$UNIT_NAME" >/dev/null 2>&1
    if [[ $NO_START -eq 1 && $was_active -eq 0 ]]; then
        ok "Unit installed and enabled, not started (--no-start)."
    else
        systemctl start "$UNIT_NAME"
        sleep 3
        if systemctl is-active --quiet "$UNIT_NAME"; then ok "$UNIT_NAME is running"
        else
            warn "$UNIT_NAME did not stay up. Look at: journalctl -u $UNIT_NAME -n 50"
            [[ -d "$PREFIX.prev" ]] && warn "Previous version kept at $PREFIX.prev"
        fi
    fi
    MF_METAL=1
}

setup_state_dirs() {
    local apache_root
    apache_root="$(sed -n 's:.*<apache-root>\([^<]*\)</apache-root>.*:\1:p' "$REPO_ROOT/configuration/nwe-config.xml" 2>/dev/null | head -1 || true)"
    if [[ $DRY_RUN -eq 1 ]]; then dry "create $CONF_DIR, $STATE_DIR, $LOG_DIR; seed configuration/ (no-clobber), authentication/*.example, data/ (no-clobber)"; return 0; fi
    install -d -o root -g "$SVC_USER" -m 0750 "$CONF_DIR" "$CONF_DIR/configuration" "$CONF_DIR/authentication"
    install -d -o "$SVC_USER" -g "$SVC_USER" -m 0750 "$STATE_DIR" "$STATE_DIR/data" "$STATE_DIR/database" "$STATE_DIR/database/fallback"
    install -d -o "$SVC_USER" -g "$SVC_USER" -m 0750 "$LOG_DIR"

    # no-clobber: a local edit always wins; report where shipped defaults moved on
    local f rel changed=0
    while IFS= read -r -d '' f; do
        rel="${f#"$REPO_ROOT"/configuration/}"
        if [[ -e "$CONF_DIR/configuration/$rel" ]]; then
            cmp -s "$f" "$CONF_DIR/configuration/$rel" || { cp -f "$f" "$CONF_DIR/configuration/$rel.dist"; changed=$((changed + 1)); }
        else
            install -D -o root -g "$SVC_USER" -m 0640 "$f" "$CONF_DIR/configuration/$rel"
        fi
    done < <(find "$REPO_ROOT/configuration" -type f -print0)
    [[ $changed -gt 0 ]] && info "$changed config file(s) differ from shipped defaults; new defaults written as *.dist next to them."
    for f in "$REPO_ROOT"/authentication/*.example; do
        [[ -e "$f" ]] && [[ ! -e "$CONF_DIR/authentication/$(basename "$f")" ]] && \
            install -o root -g "$SVC_USER" -m 0640 "$f" "$CONF_DIR/authentication/$(basename "$f")"
    done
    [[ -e "$CONF_DIR/authentication/mysql.auth.xml" ]] || \
        warn "No $CONF_DIR/authentication/mysql.auth.xml. Copy mysql.auth.xml.example there and fill it in (mode 0640, group $SVC_USER). Credentials from the checkout are deliberately NOT copied."
    if [[ ! -e "$CONF_DIR/nwe-credentials" ]]; then
        install -o root -g "$SVC_USER" -m 0640 "$REPO_ROOT/.nwe-credentials.example" "$CONF_DIR/nwe-credentials"
        warn "Edit $CONF_DIR/nwe-credentials (NWE_DB_PASS=CHANGE_ME). Chat and Emeter read it."
    fi
    [[ -f "$STATE_DIR/data/distribution-edition.txt" ]] || echo free > "$STATE_DIR/data/distribution-edition.txt"
    # seed bulk data once
    if [[ -d "$REPO_ROOT/data" ]]; then
        (cd "$REPO_ROOT/data" && find . -type f ! -name '*.pid' -print0) | while IFS= read -r -d '' f; do
            [[ -e "$STATE_DIR/data/$f" ]] || install -D -o "$SVC_USER" -g "$SVC_USER" -m 0640 "$REPO_ROOT/data/$f" "$STATE_DIR/data/$f"
        done
    fi
    chown -hR "$SVC_USER:$SVC_USER" "$STATE_DIR" "$LOG_DIR"

    # Apache-served output dir named in nwe-config.xml
    if [[ -n "$apache_root" && "$apache_root" == /var/www/* ]]; then
        if [[ ! -e "$apache_root" ]]; then
            if install -d -o "$SVC_USER" -g "$SVC_USER" -m 0755 "$apache_root"; then ok "Created $apache_root for $SVC_USER"; else warn "Could not create $apache_root; NWE will not be able to publish there."; fi
        elif ! runuser -u "$SVC_USER" -- test -w "$apache_root" 2>/dev/null; then
            if [[ $GRANT_APACHE_ROOT -eq 1 ]] && command -v setfacl >/dev/null; then
                setfacl -m "u:$SVC_USER:rwx" "$apache_root" && setfacl -d -m "u:$SVC_USER:rwx" "$apache_root" \
                    && ok "Granted $SVC_USER rwx on $apache_root (ACL, this directory only)." \
                    || warn "setfacl failed on $apache_root."
            else
                info "$apache_root exists and $SVC_USER cannot write to it; left untouched. NWE falls back to $PREFIX/nwe-files for published files. Add --grant-apache-root to give it an ACL on that one directory."
            fi
        fi
    fi
}

REBUILT_OUT=""
rebuild_classes() {
    step "Rebuild classes (JDK $JAVA_MIN)"
    local jc="$JAVA_HOME_USE/bin/javac" out="$TMP/out" list="$TMP/sources.txt" d cp
    if [[ $DRY_RUN -eq 1 ]]; then dry "javac --release $JAVA_MIN (sources listed in pom.xml) → used instead of out/"; return 0; fi
    [[ -x "$jc" ]] || die "javac not found in $JAVA_HOME_USE"
    mkdir -p "$out"
    { find "$REPO_ROOT/source" -name '*.java'
      for d in $(grep -oP '(?<=\$\{project\.basedir\}/)modules/[^<]+/source' "$REPO_ROOT/pom.xml"); do
          [[ -d "$REPO_ROOT/$d" ]] && find "$REPO_ROOT/$d" -name '*.java'
      done; } | sort -u > "$list"
    cp="$(find "$REPO_ROOT/jars/djl" "$REPO_ROOT/jars/jpcap" -name '*.jar' 2>/dev/null | tr '\n' ':')$REPO_ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:$REPO_ROOT/jars/lanterna-3.1.5.jar"
    if "$jc" --release "$JAVA_MIN" -nowarn -cp "$cp" -d "$out" "@$list" 2> "$TMP/javac.log" && [[ -f "$out/Main.class" ]]; then
        REBUILT_OUT="$out"
        ok "Compiled $(find "$out" -name '*.class' | wc -l) classes from $(wc -l < "$list") sources."
    else
        grep 'error:' "$TMP/javac.log" | head -10 >&2 || true
        die "Rebuild failed (see errors above). Nothing was installed. Fix the compile errors, or build out/ yourself (bash bash/NWE.install.sh) and drop --rebuild."
    fi
}

# ── webapp install ──────────────────────────────────────────────────────────
DEPLOYED_CTX=(); SKIPPED_CTX=()

selected_module() {   # $1 = context default name
    [[ -z "$ONLY_MODULES" ]] && return 0
    [[ ",$ONLY_MODULES," == *",$1,"* ]]
}

tomcat_ctx_taken() {  # $1 ctx → prints reason, returns 0 if taken by something not ours
    local ctx="$1" f
    mf_has context "$ctx" && return 1
    for f in "$TOMCAT_APPBASE/$ctx" "$TOMCAT_APPBASE/$ctx.war"; do
        [[ -e "$f" ]] && { echo "$f already exists in Tomcat"; return 0; }
    done
    for f in "$TOMCAT_BASE"/conf/*/*/"$ctx.xml" "$TOMCAT_BASE"/conf/Catalina/*/"$ctx.xml"; do
        [[ -e "$f" ]] && { echo "context descriptor $f already exists"; return 0; }
    done
    return 1
}

build_war() {   # $1 src webapp dir  $2 war out path  $3 ctx label
    local src="$1" war="$2" ctx="$3" stage="$TMP/stage/$3" jsrc
    rm -rf "$stage"; mkdir -p "$stage/WEB-INF/lib"
    cp -a "$src/." "$stage/"
    find "$REPO_ROOT/jars/mysql" -maxdepth 1 -name 'mysql-connector-j-*.jar' -exec cp {} "$stage/WEB-INF/lib/" \; 2>/dev/null || true
    jsrc="${src%/webapp}/java"
    if [[ -d "$jsrc" ]]; then
        local api="${TOMCAT_SERVLET_API:-}"
        [[ -n "$api" ]] || api="$REPO_ROOT/jars/jakarta.servlet-api-6.1.0.jar"
        mkdir -p "$stage/WEB-INF/classes"
        "${JAVAC_WEB}" --release "$TOMCAT_JAVA_RELEASE" -nowarn -cp "$api:$stage/WEB-INF/lib/*" -d "$stage/WEB-INF/classes" \
            $(find "$jsrc" -name '*.java') 2> "$TMP/javac-$ctx.log" || { tail -5 "$TMP/javac-$ctx.log" >&2; return 1; }
    fi
    "${JAR_WEB}" --create --file "$war" -C "$stage" .
}

install_webapps() {
    if ! select_tomcat; then SKIPPED_CTX+=("(all: no usable Tomcat)"); return 0; fi
    TMP="${TMP:-$(mktemp -d)}"
    sync_tomcat_config

    # tools to build WARs: any JDK will do
    local jh; jh="$(find_java || true)"
    JAVAC_WEB="${jh:+$jh/bin/}javac"; JAR_WEB="${jh:+$jh/bin/}jar"
    command -v "$JAVAC_WEB" >/dev/null && command -v "$JAR_WEB" >/dev/null || \
        { [[ $DRY_RUN -eq 1 ]] && warn "No JDK for building WARs yet." || die "Building WARs needs a JDK (javac, jar)."; }

    local owner; owner="$(stat -c '%U:%G' "$TOMCAT_APPBASE")"
    local apache_ok=0
    if [[ $NO_APACHE -eq 0 ]] && discover_apache; then apache_ok=1; fi
    step "Deploying WARs"

    local entry rel ctx src war reason
    for entry in "${MODULE_MAP[@]}"; do
        rel="${entry%%:*}"; ctx="$CTX_PREFIX${entry##*:}"
        selected_module "${entry##*:}" || selected_module "$ctx" || continue
        src="$REPO_ROOT/modules/$rel/servlets/servlet/src/main/webapp"
        [[ -d "$src" ]] || continue
        if reason="$(tomcat_ctx_taken "$ctx")"; then
            skip "/$ctx: $reason. Left alone (use --context-prefix to deploy side by side)."; SKIPPED_CTX+=("$ctx"); continue
        fi
        if [[ $apache_ok -eq 1 ]] && reason="$(apache_path_taken "$ctx")"; then
            warn "/$ctx: $reason. Deploying to Tomcat only; no Apache mapping for it."
            APACHE_SKIP+=("$ctx")
        fi
        if [[ $DRY_RUN -eq 1 ]]; then dry "build + deploy /$ctx  ← modules/$rel"; DEPLOYED_CTX+=("$ctx"); continue; fi
        war="$TMP/$ctx.war"
        if ! build_war "$src" "$war" "$ctx"; then warn "/$ctx: build failed; skipped."; SKIPPED_CTX+=("$ctx"); continue; fi
        # copy under a name Tomcat ignores, then rename: Tomcat never sees a partial WAR
        cp "$war" "$TOMCAT_APPBASE/$ctx.war.jwstf-tmp"
        chown "$owner" "$TOMCAT_APPBASE/$ctx.war.jwstf-tmp"; chmod 0640 "$TOMCAT_APPBASE/$ctx.war.jwstf-tmp"
        mv "$TOMCAT_APPBASE/$ctx.war.jwstf-tmp" "$TOMCAT_APPBASE/$ctx.war"
        ok "/$ctx → $TOMCAT_APPBASE/$ctx.war"
        DEPLOYED_CTX+=("$ctx")
    done
    [[ ${#DEPLOYED_CTX[@]} -gt 0 ]] || { info "Nothing new deployed to Tomcat."; }

    write_manifest      # record ownership before anything else can fail
    if [[ $DRY_RUN -eq 0 && ${#DEPLOYED_CTX[@]} -gt 0 ]]; then activate_tomcat; fi
    if [[ $apache_ok -eq 1 ]]; then configure_apache; fi
}

APACHE_SKIP=()

activate_tomcat() {
    local running=0 ctx t
    [[ -n "$TOMCAT_SVC" ]] && systemctl is-active --quiet "$TOMCAT_SVC" 2>/dev/null && running=1
    if [[ $RESTART_TOMCAT -eq 1 && -n "$TOMCAT_SVC" ]]; then
        systemctl restart "$TOMCAT_SVC"; ok "Restarted $TOMCAT_SVC"
    elif [[ "$TOMCAT_AUTODEPLOY" == "true" && $running -eq 1 ]]; then
        info "Tomcat autoDeploy is on; waiting for it to unpack the WARs (up to 60 s)…"
        for ctx in "${DEPLOYED_CTX[@]}"; do
            for t in $(seq 1 30); do [[ -d "$TOMCAT_APPBASE/$ctx" ]] && break; sleep 2; done
            [[ -d "$TOMCAT_APPBASE/$ctx" ]] || warn "/$ctx not unpacked yet; check Tomcat's catalina log."
        done
    elif [[ "$TOMCAT_AUTODEPLOY" == "true" ]]; then
        info "autoDeploy is on but no Tomcat service was detected as running; a running Tomcat will pick the WARs up on its own."
    else
        warn "Tomcat has autoDeploy off. Existing apps were NOT restarted; restart Tomcat when convenient or re-run with --restart-tomcat."
    fi
}

configure_apache() {
    step "Apache2 proxy"
    local ctxs=() c s
    for c in "${DEPLOYED_CTX[@]}" $(mf_values context); do
        for s in "${APACHE_SKIP[@]:-}"; do [[ "$c" == "$s" ]] && continue 2; done
        [[ " ${ctxs[*]:-} " == *" $c "* ]] || ctxs+=("$c")
    done
    [[ ${#ctxs[@]} -gt 0 ]] || { info "No contexts to proxy."; return 0; }

    if [[ -e "$APACHE_CONF_FILE" ]] && ! grep -qF "$APACHE_CONF_MARK" "$APACHE_CONF_FILE"; then
        warn "$APACHE_CONF_FILE exists and is not ours; not touching Apache."; return 0
    fi
    TMP="${TMP:-$(mktemp -d)}"
    local conf="$TMP/$APACHE_CONF_NAME.conf"
    {
        echo "$APACHE_CONF_MARK — regenerated on every install; do not edit."
        echo "# Applies to every vhost (conf-enabled). Contexts below are served by Tomcat on 127.0.0.1:$TOMCAT_PORT."
        for c in "${ctxs[@]}"; do
            cat <<EOF

RedirectMatch "^/${c//./\\.}\$" "/$c/"
<Location "/$c/">
    ProxyPass "http://127.0.0.1:$TOMCAT_PORT/$c/"
    ProxyPassReverse "http://127.0.0.1:$TOMCAT_PORT/$c/"
    ProxyPreserveHost On
</Location>
EOF
        done
    } > "$conf"

    if [[ $DRY_RUN -eq 1 ]]; then dry "a2enmod proxy proxy_http (only if not loaded); write $APACHE_CONF_FILE for: ${ctxs[*]}; a2enconf; apache2ctl configtest; reload (rollback on failure)"; return 0; fi

    local backup="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)" had_conf=0 mods=""
    mkdir -p "$backup"
    [[ -e "$APACHE_CONF_FILE" ]] && { had_conf=1; cp -a "$APACHE_CONF_FILE" "$backup/"; }
    local loaded; loaded="$(apache2ctl -M 2>/dev/null || true)"
    for m in proxy proxy_http alias; do
        grep -q " ${m}_module " <<<"$loaded" || { a2enmod -q "$m" >/dev/null; mods+="$m "; }
    done
    [[ -n "$mods" ]] && info "Enabled Apache module(s): $mods (left enabled on uninstall)"
    install -m 0644 "$conf" "$APACHE_CONF_FILE"
    a2enconf -q "$APACHE_CONF_NAME" >/dev/null
    if apache2ctl configtest >"$TMP/configtest.log" 2>&1; then
        if [[ $APACHE_ACTIVE -eq 1 ]]; then systemctl reload apache2 && ok "Apache reloaded (graceful); proxying: ${ctxs[*]}"
        else ok "Apache config valid; Apache is not running, so nothing reloaded."; fi
        APACHE_CONF_DONE=1
    else
        cat "$TMP/configtest.log" >&2
        a2disconf -q "$APACHE_CONF_NAME" >/dev/null || true
        if [[ $had_conf -eq 1 ]]; then cp -a "$backup/$APACHE_CONF_NAME.conf" "$APACHE_CONF_FILE"; a2enconf -q "$APACHE_CONF_NAME" >/dev/null; else rm -f "$APACHE_CONF_FILE"; fi
        warn "apache2ctl configtest failed; our change was rolled back. Apache is unchanged."
    fi
}
APACHE_CONF_DONE=0; MF_METAL=0

write_manifest() {
    [[ $DRY_RUN -eq 1 ]] && return 0
    local keep=() c
    # contexts we already owned stay owned
    for c in $(mf_values context) "${DEPLOYED_CTX[@]:-}"; do
        [[ -n "$c" && " ${keep[*]:-} " != *" $c "* ]] && keep+=("$c")
    done
    mkdir -p "$STATE_DIR"
    {
        echo "version=1"
        echo "installed=$(date -u +%FT%TZ)"
        echo "mode=$MODE"
        echo "prefix=$PREFIX"
        echo "user=$SVC_USER"
        if [[ $MF_METAL -eq 1 || -n "$(mf_first unit)" ]]; then echo "unit=$UNIT_NAME"; fi
        if [[ -n "$TOMCAT_BASE" ]]; then
            echo "tomcat_base=$TOMCAT_BASE"; echo "tomcat_appbase=$TOMCAT_APPBASE"; echo "tomcat_service=$TOMCAT_SVC"
        elif [[ -n "$(mf_first tomcat_base)" ]]; then
            echo "tomcat_base=$(mf_first tomcat_base)"; echo "tomcat_appbase=$(mf_first tomcat_appbase)"; echo "tomcat_service=$(mf_first tomcat_service)"
        fi
        if [[ $APACHE_CONF_DONE -eq 1 ]] || [[ -n "$(mf_first apache_conf)" ]]; then echo "apache_conf=$APACHE_CONF_NAME"; fi
        for c in "${keep[@]:-}"; do [[ -n "$c" ]] && echo "context=$c"; done
    } > "$MANIFEST.new"
    chmod 0644 "$MANIFEST.new"; mv "$MANIFEST.new" "$MANIFEST"
}

# ── commands ────────────────────────────────────────────────────────────────
cmd_install() {
    need_root
    command -v systemctl >/dev/null || die "systemd is required."
    [[ -d "$REPO_ROOT/modules" && -d "$REPO_ROOT/source" ]] || die "Run this from a full checkout (expected $REPO_ROOT/modules and source/)."
    [[ -r /etc/os-release ]] && . /etc/os-release
    info "Host: ${PRETTY_NAME:-unknown}   Mode: $MODE   $([[ $DRY_RUN -eq 1 ]] && echo '(PLAN ONLY, nothing is changed)')"
    [[ "${ID:-}" == ubuntu || "${ID_LIKE:-}" == *debian* ]] || warn "Not Ubuntu/Debian; paths and apt assumptions may be wrong."

    [[ $DRY_RUN -eq 1 ]] || install -d -m 0755 "$STATE_DIR"
    if want_metal;  then ensure_java; check_ports; install_metal; fi
    if want_webapp; then install_webapps; fi
    write_manifest
    summary
}

summary() {
    step "Summary"
    if [[ $DRY_RUN -eq 1 ]]; then info "Plan only. Re-run with 'install' to apply."; fi
    if want_metal;  then info "metal : $PREFIX  (unit $UNIT_NAME; config $CONF_DIR; state $STATE_DIR; logs $LOG_DIR)"; fi
    if want_webapp; then
        info "webapp: $([[ $DRY_RUN -eq 1 ]] && echo "would deploy" || echo deployed) ${#DEPLOYED_CTX[@]} context(s): ${DEPLOYED_CTX[*]:-none}"
        [[ ${#SKIPPED_CTX[@]} -gt 0 ]] && info "        skipped: ${SKIPPED_CTX[*]}"
        [[ -n "$TOMCAT_BASE" ]] && info "        Tomcat http://127.0.0.1:$TOMCAT_PORT/<context>/"
    fi
    info "Databases: run bash/MySQL.setup.sh and modules/*/servlets/setup-db.sh yourself; this script does not touch MySQL."
    [[ $N_WARN -gt 0 ]] && info "$N_WARN warning(s) above."
    return 0
}

cmd_status() {
    step "Status"
    if [[ ! -r "$MANIFEST" ]]; then info "No install manifest at $MANIFEST (nothing installed by this script)."; else cat "$MANIFEST"; fi
    systemctl is-active "$UNIT_NAME" 2>/dev/null | sed 's/^/   service jwstf: /' || true
    [[ -e "$APACHE_CONF_FILE" ]] && info "Apache conf present: $APACHE_CONF_FILE"
    return 0
}

cmd_uninstall() {
    need_root
    [[ -r "$MANIFEST" ]] || die "No manifest at $MANIFEST; refusing to remove anything I cannot prove I installed."
    step "Uninstall (only what the manifest lists)"
    local prefix tb ab ts c
    prefix="$(mf_first prefix)"; tb="$(mf_first tomcat_base)"; ab="$(mf_first tomcat_appbase)"; ts="$(mf_first tomcat_service)"

    if [[ -n "$(mf_first apache_conf)" && -e "$APACHE_CONF_FILE" ]]; then
        if grep -qF "$APACHE_CONF_MARK" "$APACHE_CONF_FILE"; then
            a2disconf -q "$APACHE_CONF_NAME" >/dev/null || true; rm -f "$APACHE_CONF_FILE"
            if apache2ctl configtest >/dev/null 2>&1; then systemctl is-active --quiet apache2 && systemctl reload apache2; ok "Apache proxy conf removed (modules left enabled)"
            else warn "apache2ctl configtest fails after removal; check Apache manually."; fi
        else warn "$APACHE_CONF_FILE is not ours any more; left alone."; fi
    fi
    if [[ -n "$ab" ]]; then
        for c in $(mf_values context); do
            [[ "$c" =~ ^[A-Za-z0-9._-]+$ ]] || continue
            rm -f "$ab/$c.war"; rm -rf "${ab:?}/$c"; ok "Removed Tomcat context /$c"
        done
    fi
    [[ -z "$prefix" || "$prefix" == /?*/?* ]] || die "Manifest prefix '$prefix' looks unsafe; not removing."
    if [[ -n "$(mf_first unit)" && -e "$UNIT_FILE" ]]; then
        systemctl disable --now "$UNIT_NAME" >/dev/null 2>&1 || true
        grep -qF "$UNIT_MARK" "$UNIT_FILE" && rm -f "$UNIT_FILE"; systemctl daemon-reload
        [[ -n "$prefix" && -d "$prefix" ]] && rm -rf "$prefix" "$prefix.prev"
        ok "Service and $prefix removed"
    fi
    if [[ $PURGE -eq 1 ]]; then
        rm -rf "$CONF_DIR" "$STATE_DIR" "$LOG_DIR"; ok "Purged $CONF_DIR, $STATE_DIR, $LOG_DIR"
    else
        rm -f "$MANIFEST"; info "Kept $CONF_DIR, $STATE_DIR, $LOG_DIR (use --purge to delete). User '$SVC_USER' kept."
    fi
}

case "$CMD" in
    install|plan) cmd_install ;;
    status)       cmd_status ;;
    uninstall)    cmd_uninstall ;;
esac
