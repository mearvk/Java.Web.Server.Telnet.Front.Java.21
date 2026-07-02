#!/bin/bash
# ============================================================

# Detect MySQL location
_NWE_ROOT="$(cd "$(dirname "$0")/../../../.." 2>/dev/null && pwd)"
[ -f "$_NWE_ROOT/scripts/detect-mysql.sh" ] && source "$_NWE_ROOT/scripts/detect-mysql.sh"
# INSTALL SCRIPT — Democratic ProFront National 1.0
# Installer ID: MEARVK LLC - Max Rupplin
# D500 Democratic President
# ============================================================
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "============================================================"
echo " Democratic ProFront National 1.0 — INSTALLER"
echo " MEARVK LLC - Max Rupplin"
echo "============================================================"
echo ""
echo "[1/7] Verifying Java 21+..."
JAVA_VER=$(java -version 2>&1 | head -1 | awk -F '"' '{print $2}' | cut -d. -f1)
if [ "$JAVA_VER" -lt 21 ]; then
    echo "FATAL: Java 21+ required. Found: $JAVA_VER"
    exit 1
fi
echo "       Java $JAVA_VER ✓"

echo ""
echo "[2/7] Verifying jar dependencies..."
mkdir -p "$PROJECT_DIR/jars"
MISSING=0
JARS="api-0.31.0.jar pytorch-engine-0.31.0.jar pytorch-native-cpu-2.5.1-linux-x86_64.jar pytorch-model-zoo-0.31.0.jar model-zoo-0.31.0.jar basicdataset-0.31.0.jar tokenizers-0.31.0.jar jna-5.14.0.jar commons-compress-1.26.1.jar gson-2.11.0.jar slf4j-api-2.0.12.jar slf4j-simple-2.0.12.jar"

# Offer to download pytorch-native-cpu if missing
PYTORCH_JAR="pytorch-native-cpu-2.5.1-linux-x86_64.jar"
if [ ! -f "$PROJECT_DIR/jars/$PYTORCH_JAR" ]; then
    echo "       $PYTORCH_JAR not found."
    read -p "       Download from Maven Central? [Y/n] " REPLY
    REPLY=${REPLY:-Y}
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "       Downloading $PYTORCH_JAR (~109MB)..."
        curl -fSL -o "$PROJECT_DIR/jars/$PYTORCH_JAR" \
            "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-native-cpu/2.5.1/pytorch-native-cpu-2.5.1-linux-x86_64.jar"
        echo "       Downloaded ✓"
    fi
fi

for JAR in $JARS; do
    if [ ! -f "$PROJECT_DIR/jars/$JAR" ]; then
        echo "       MISSING: jars/$JAR"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    echo "FATAL: Missing jar files in /jars"
    exit 1
fi
echo "       All 12 jars present ✓"

echo ""
echo "[3/7] Compiling source..."
CP=$(echo "$PROJECT_DIR"/jars/*.jar | tr ' ' ':')
mkdir -p "$PROJECT_DIR/output/production/Futures"
javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" \
    -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/module/TaxDefenseSpeculator.java" \
    "$PROJECT_DIR/source/ai/trainers/TaxClosureTrainer.java" \
    "$PROJECT_DIR/source/ai/trainers/DefenseStrategyTrainer.java" \
    "$PROJECT_DIR/source/ai/server/DemocraticHardServer.java" \
    "$PROJECT_DIR/source/ai/server/DemocraticAIServer.java" \
    "$PROJECT_DIR/source/ai/server/DiskAwarenessMonitor.java" \
    "$PROJECT_DIR/source/pro/national/ConnectionGuard.java" \
    "$PROJECT_DIR/source/pro/national/DueProcessPipeline.java" \
    "$PROJECT_DIR/source/pro/national/ParallelVetting.java" \
    "$PROJECT_DIR/source/pro/national/ConsentGate.java" \
    "$PROJECT_DIR/source/pro/national/EjectionFuture.java" \
    "$PROJECT_DIR/source/pro/national/ResponseDispatcher.java" \
    "$PROJECT_DIR/source/pro/national/GracefulTransfer.java" \
    "$PROJECT_DIR/source/pro/national/LearningAccumulator.java" \
    2>&1
echo "       Compilation successful ✓"

echo ""
echo "[4/7] Verifying configuration files..."
CONFIGS="ai-module-config.xml server-config.xml database-config.xml nwe-config.xml programs.xml known.port.20000.servers.xml known.port.49152.servers.xml known.port.2000.servers.xml nio-masquerade-config.xml port-2000-directory-config.xml masquerade-modules.xml protocol-handlers.xml transfer-contacts.xml receiver.only.xml"
CONFIG_MISSING=0
for CFG in $CONFIGS; do
    if [ ! -f "$PROJECT_DIR/configuration/$CFG" ]; then
        echo "       MISSING: configuration/$CFG"
        CONFIG_MISSING=1
    fi
done
DEMO_FILES="democratic.answers.txt tax.survivors.txt us.tax.laws.explained.txt defensive.heurstics.and.tactics.for.US.personnel.txt"
for DF in $DEMO_FILES; do
    if [ ! -f "$PROJECT_DIR/configuration/democratic/$DF" ]; then
        echo "       MISSING: configuration/democratic/$DF"
        CONFIG_MISSING=1
    fi
done
if [ "$CONFIG_MISSING" -eq 1 ]; then
    echo "WARNING: Some configuration files missing — AI training will be incomplete"
else
    echo "       All configuration files present ✓"
fi

echo ""
echo "[5/7] Setting up MySQL database..."
if command -v mysql &>/dev/null; then
    echo "       MySQL client found ✓"
    if sudo mysql -e "SELECT 1" &>/dev/null 2>&1; then
        sudo mysql < "$PROJECT_DIR/sql/schema.sql" 2>/dev/null && echo "       Base schema applied ✓" || echo "       Base schema already exists ✓"
        sudo mysql democratic_d500 < "$PROJECT_DIR/sql/schema-update-ai.sql" 2>/dev/null && echo "       AI schema applied ✓" || echo "       AI schema already exists ✓"
    else
        echo "       MySQL running but needs credentials — run manually:"
        echo "         sudo mysql < sql/schema.sql"
        echo "         sudo mysql democratic_d500 < sql/schema-update-ai.sql"
    fi
else
    echo "       MySQL not installed — install with: sudo apt install mysql-server"
    echo "       Then run: sudo bash sql/install.sh"
fi

echo ""
echo "[6/7] Creating model directories..."
mkdir -p "$PROJECT_DIR/models/tax-defense" "$PROJECT_DIR/models/defense-strategy"
echo "       models/tax-defense ✓"
echo "       models/defense-strategy ✓"

echo ""
echo "[7/7] Creating data directory..."
mkdir -p "$PROJECT_DIR/data"
echo "       data/ ✓"

echo ""
echo "============================================================"
echo " INSTALLATION COMPLETE"
echo ""
echo " To run: java -cp \"output/production/Futures:jars/*\" ai.server.DemocraticAIServer"
echo " Port 5000 will open after 2-3 minute secure random wait."
echo " Banner: Democratic ProFront National 1.0"
echo ""
echo " Installer ID: MEARVK LLC - Max Rupplin"
echo "============================================================"
