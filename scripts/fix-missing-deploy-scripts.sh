#!/bin/bash
# fix-missing-deploy-scripts.sh — Creates deploy scripts for nested-repo modules
# Run on production server: sudo bash scripts/fix-missing-deploy-scripts.sh
# These modules have their own .git/ so their servlets/ dirs don't propagate to the parent repo.
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "[*] Creating missing deploy scripts for nested-repo modules..."

# ── Futures deploy-local.sh ──────────────────────────────────────────────────
FUTURES_DIR="$PROJECT_ROOT/modules/black/red/Futures/servlets"
mkdir -p "$FUTURES_DIR/servlet/src/main/webapp/WEB-INF"
if [ ! -f "$FUTURES_DIR/deploy-local.sh" ]; then
cat > "$FUTURES_DIR/deploy-local.sh" << 'EOF'
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBAPP_SRC="$SCRIPT_DIR/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/futures"
echo "[*] Deploying Futures™ to $DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
[ -d "$WEBAPP_SRC" ] && cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/" || echo "[WARN] No webapp source found"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
echo "[OK] Futures™ deployed at /futures"
EOF
chmod +x "$FUTURES_DIR/deploy-local.sh"
echo "  [OK] Created: $FUTURES_DIR/deploy-local.sh"
else
echo "  [SKIP] Already exists: $FUTURES_DIR/deploy-local.sh"
fi

# ── GDGH deploy-local.sh ────────────────────────────────────────────────────
GDGH_DIR="$PROJECT_ROOT/modules/black/presidential/Green.Durham.Grass.and.Herb/servlets"
mkdir -p "$GDGH_DIR/servlet/src/main/webapp/WEB-INF"
if [ ! -f "$GDGH_DIR/deploy-local.sh" ]; then
cat > "$GDGH_DIR/deploy-local.sh" << 'EOF'
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBAPP_SRC="$SCRIPT_DIR/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/gdgh"
echo "[*] Deploying Green.Durham.Grass.and.Herb™ to $DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
[ -d "$WEBAPP_SRC" ] && cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/" || echo "[WARN] No webapp source found"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
echo "[OK] Green.Durham.Grass.and.Herb™ deployed at /gdgh"
EOF
chmod +x "$GDGH_DIR/deploy-local.sh"
echo "  [OK] Created: $GDGH_DIR/deploy-local.sh"
else
echo "  [SKIP] Already exists: $GDGH_DIR/deploy-local.sh"
fi

echo "[*] Done. Re-run: sudo bash scripts/web/deploy-all.sh"
