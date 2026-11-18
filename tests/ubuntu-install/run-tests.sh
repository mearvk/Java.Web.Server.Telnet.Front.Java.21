#!/usr/bin/env bash
# Integration test for bash/NWE.ubuntu-install.sh on a REAL Ubuntu 22.04/24.04
# host (systemd, apt, Apache2, Tomcat 10). Run as root on a disposable machine:
#
#   sudo bash tests/ubuntu-install/run-tests.sh
#
# It is what .github/workflows/ubuntu-installer.yml runs, and what
# tests/ubuntu-install/docker-run.sh runs inside a systemd container.
#
# The scenario builds a "server that already hosts things":
#   * apt Apache2 with a vhost that already proxies /library
#   * a static directory /var/www/html/calendar
#   * apt Tomcat 10 with an unrelated webapp /chat carrying a marker file
#   * something already listening on one NWE port (second run only)
# then checks that the installer deploys around all of it, stays idempotent,
# refuses on a port conflict, and uninstalls only its own files.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL="$REPO/bash/NWE.ubuntu-install.sh"
FAILS=0; PASSES=0
pass() { printf '  PASS  %s\n' "$*"; PASSES=$((PASSES + 1)); }
fail() { printf '  FAIL  %s\n' "$*"; FAILS=$((FAILS + 1)); }
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
section() { printf '\n== %s ==\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "run as root"; exit 2; }
[[ -r /etc/os-release ]] && . /etc/os-release
[[ "${ID:-}" == ubuntu ]] || { echo "not Ubuntu (${ID:-?}); refusing to run"; exit 2; }
export DEBIAN_FRONTEND=noninteractive

section "Prepare an already-populated server"
apt-get update -qq
apt-get install -y -qq apache2 tomcat10 curl python3 iproute2 unzip acl >/dev/null
a2enmod -q proxy proxy_http >/dev/null
systemctl enable --now apache2 tomcat10 >/dev/null 2>&1

mkdir -p /var/www/html/calendar && echo static > /var/www/html/calendar/index.html
cat > /etc/apache2/sites-available/preexisting.conf <<'EOF'
<VirtualHost *:80>
    ProxyPass /library http://127.0.0.1:9/library
</VirtualHost>
EOF
a2ensite -q preexisting >/dev/null
mkdir -p /var/lib/tomcat10/webapps/chat && echo mine > /var/lib/tomcat10/webapps/chat/MARKER
chown -R tomcat:tomcat /var/lib/tomcat10/webapps/chat
apache2ctl configtest >/dev/null 2>&1 && systemctl reload apache2
check "baseline: apache2 active" systemctl is-active --quiet apache2
check "baseline: tomcat10 active" systemctl is-active --quiet tomcat10

section "plan changes nothing"
before="$(find /etc/apache2 /var/lib/tomcat10/webapps /etc/systemd/system -type f 2>/dev/null | sort | xargs -r md5sum | md5sum)"
bash "$INSTALL" plan --mode both >/tmp/plan.out 2>&1; rc=$?
after="$(find /etc/apache2 /var/lib/tomcat10/webapps /etc/systemd/system -type f 2>/dev/null | sort | xargs -r md5sum | md5sum)"
[[ $rc -eq 0 ]] && pass "plan exits 0" || fail "plan exit $rc"
[[ "$before" == "$after" ]] && pass "plan left apache/tomcat/systemd files untouched" || fail "plan modified files"
check "plan mentions skipping /chat" grep -q '/chat' /tmp/plan.out

section "port conflict refuses to install metal"
python3 -m http.server 49152 --bind 127.0.0.1 >/dev/null 2>&1 &
HOG=$!; sleep 1
bash "$INSTALL" install --mode metal --install-deps --no-start >/tmp/conflict.out 2>&1; rc=$?
[[ $rc -ne 0 ]] && pass "install aborted on busy port (rc=$rc)" || fail "install ignored a busy port"
check "no unit file was written" test ! -e /etc/systemd/system/jwstf.service
kill "$HOG" 2>/dev/null; wait "$HOG" 2>/dev/null

section "install --mode both"
bash "$INSTALL" install --mode both --install-deps >/tmp/install.out 2>&1; rc=$?
[[ $rc -eq 0 ]] && pass "install exits 0" || { fail "install exit $rc"; tail -30 /tmp/install.out; }
check "jwstf.service enabled"             systemctl is-enabled --quiet jwstf
check "/opt/jwstf/out/Main.class present" test -f /opt/jwstf/out/Main.class
check "service user exists"               id jwstf
check "out/ owned by root, rest by jwstf" bash -c '[[ "$(stat -c %U /opt/jwstf/out)" == root && "$(stat -c %U /opt/jwstf/scripts)" == jwstf ]]'
check "credentials file not world readable" bash -c '[[ "$(stat -c %a /etc/jwstf/nwe-credentials)" == 640 ]]'
check "real mysql.auth.xml NOT copied"    test ! -e /etc/jwstf/authentication/mysql.auth.xml
check "nwe-config.xml parses"             python3 -c "import xml.etree.ElementTree as E;E.parse('/etc/jwstf/configuration/nwe-config.xml')"
check "app config points at apt Tomcat"   grep -q '<install-dir>/usr/share/tomcat10</install-dir>' /etc/jwstf/configuration/nwe-config.xml
sleep 8
check "jwstf still running after 8 s"     systemctl is-active --quiet jwstf

section "existing things untouched"
check "pre-existing /chat kept (marker)"  test "$(cat /var/lib/tomcat10/webapps/chat/MARKER 2>/dev/null)" = mine
check "no chat.war created"               test ! -e /var/lib/tomcat10/webapps/chat.war
check "ae6e66.war deployed"               test -f /var/lib/tomcat10/webapps/ae6e66.war
check "preexisting vhost file unchanged"  grep -q 'ProxyPass /library http://127.0.0.1:9/library' /etc/apache2/sites-available/preexisting.conf
check "our conf exists"                   test -f /etc/apache2/conf-available/jwstf-proxy.conf
check "no mapping for /library"           bash -c '! grep -q "\"/library/\"" /etc/apache2/conf-available/jwstf-proxy.conf'
check "no mapping for /calendar"          bash -c '! grep -q "\"/calendar/\"" /etc/apache2/conf-available/jwstf-proxy.conf'
check "no mapping for /chat"              bash -c '! grep -q "\"/chat/\"" /etc/apache2/conf-available/jwstf-proxy.conf'
check "mapping for /ae6e66 present"       grep -q '"/ae6e66/"' /etc/apache2/conf-available/jwstf-proxy.conf
check "apache2ctl configtest passes"      apache2ctl configtest
check "apache2 still active"              systemctl is-active --quiet apache2
check "tomcat10 still active (not restarted by us)" systemctl is-active --quiet tomcat10
check "static /calendar still served"     bash -c '[[ "$(curl -s http://127.0.0.1/calendar/)" == static ]]'

section "webapp reachable through Apache (waits for Tomcat autoDeploy)"
code=000
for _ in $(seq 1 30); do
    code="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/ae6e66/)"
    [[ ! "$code" =~ ^(000|404|502|503)$ ]] && break; sleep 2
done
# any answer from the app (even a 500 for a missing database) proves Apache → Tomcat → context works
[[ ! "$code" =~ ^(000|404|502|503)$ ]] && pass "GET /ae6e66/ via Apache → $code" || fail "GET /ae6e66/ via Apache → $code"

section "second install is idempotent"
m1="$(grep -v '^installed=' /var/lib/jwstf/install-manifest | md5sum)"
echo "local edit" >> /etc/jwstf/configuration/print-method.xml
bash "$INSTALL" install --mode both >/tmp/install2.out 2>&1; rc=$?
[[ $rc -eq 0 ]] && pass "re-run exits 0" || { fail "re-run exit $rc"; tail -20 /tmp/install2.out; }
m2="$(grep -v '^installed=' /var/lib/jwstf/install-manifest | md5sum)"
[[ "$m1" == "$m2" ]] && pass "manifest unchanged" || fail "manifest changed on re-run"
check "local config edit survived"        grep -q 'local edit' /etc/jwstf/configuration/print-method.xml
check "jwstf running after upgrade"       systemctl is-active --quiet jwstf

section "uninstall removes only our files"
bash "$INSTALL" uninstall >/tmp/uninstall.out 2>&1; rc=$?
[[ $rc -eq 0 ]] && pass "uninstall exits 0" || { fail "uninstall exit $rc"; tail -20 /tmp/uninstall.out; }
check "unit gone"                         test ! -e /etc/systemd/system/jwstf.service
check "/opt/jwstf gone"                   test ! -e /opt/jwstf
check "ae6e66.war gone"                   test ! -e /var/lib/tomcat10/webapps/ae6e66.war
check "apache conf gone"                  test ! -e /etc/apache2/conf-available/jwstf-proxy.conf
check "/chat still there"                 test "$(cat /var/lib/tomcat10/webapps/chat/MARKER)" = mine
check "preexisting vhost still there"     test -f /etc/apache2/sites-available/preexisting.conf
check "apache2 still valid and active"   bash -c 'apache2ctl configtest && systemctl is-active --quiet apache2'
check "config kept without --purge"       test -d /etc/jwstf

printf '\n%d passed, %d failed\n' "$PASSES" "$FAILS"
[[ $FAILS -eq 0 ]]
