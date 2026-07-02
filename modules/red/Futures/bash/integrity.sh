#!/bin/bash
# ============================================================
# INTEGRITY CHECK — Democratic ProFront National 1.0
# Verifies file checksums, detects tampering, logs attempts
# Installer ID: MEARVK LLC - Max Rupplin
# Updated: 2026-06-25 — 39 critical files
# ============================================================
set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INTEGRITY_FILE="$PROJECT_DIR/.integrity.sha256"
LOG_FILE="$PROJECT_DIR/logging/integrity.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

mkdir -p "$PROJECT_DIR/logging"

echo "============================================================"
echo " INTEGRITY CHECK — Democratic ProFront National 1.0"
echo " $TIMESTAMP"
echo "============================================================"
echo ""

# Files to monitor for tampering (39 critical files)
CRITICAL_FILES=(
    # AI Server
    "source/ai/server/DemocraticAIServer.java"
    "source/ai/server/DemocraticHardServer.java"
    "source/ai/server/EncryptionService.java"
    "source/ai/server/OutboundPortAwareness.java"
    "source/ai/server/Pledge44HFetcher.java"
    "source/ai/server/DiskAwarenessMonitor.java"
    # AI Module
    "source/ai/module/TaxDefenseSpeculator.java"
    # AI Training
    "source/ai/training/ConfigurationTrainer.java"
    "source/ai/training/WeightPersistence.java"
    "source/ai/trainers/TaxClosureTrainer.java"
    "source/ai/trainers/DefenseStrategyTrainer.java"
    # AI Military
    "source/ai/military/HardwareAndStrikes.java"
    "source/ai/military/UptimeAccumulator.java"
    # Protective National Pipeline
    "source/pro/national/ConnectionGuard.java"
    "source/pro/national/ConsentGate.java"
    "source/pro/national/EjectionFuture.java"
    "source/pro/national/DueProcessPipeline.java"
    "source/pro/national/ParallelVetting.java"
    "source/pro/national/ResponseDispatcher.java"
    "source/pro/national/GracefulTransfer.java"
    "source/pro/national/LearningAccumulator.java"
    "source/pro/national/CoolingCircuit.java"
    # Configuration
    "configuration/ai-module-config.xml"
    "configuration/server-config.xml"
    "configuration/database-config.xml"
    "configuration/nwe-config.xml"
    "configuration/intent-regulator-config.xml"
    "configuration/nio-masquerade-config.xml"
    "configuration/blackbelt/hardware-and-strikes.xml"
    # SQL
    "sql/schema.sql"
    "sql/schema-update-ai.sql"
    "sql/schema-44h.sql"
    # Scripts
    "bash/install.sh"
    "bash/start.sh"
    "bash/shutdown.sh"
    "bash/test.sh"
    "bash/test-qa.sh"
    "bash/verify.sh"
    "bash/train.sh"
)

# Embedded SHA-256 baseline — 2026-06-25
declare -A BASELINE=(
    ["source/ai/server/DemocraticAIServer.java"]="cce6be12b45f5b0775647599279576d6c09c17de0afe2ac42d3b2f0ed1a60113"
    ["source/ai/server/DemocraticHardServer.java"]="315b378068be6fdba14514ffda7af90a17a08f557f0146c86c06122703c4f15e"
    ["source/ai/server/EncryptionService.java"]="2baf1c22da67250f9b0b599422f1de29c9cd44b95e53293897cbca8dfc6f2293"
    ["source/ai/server/OutboundPortAwareness.java"]="6beaa0546762bd7f82e1b6a1a331ae58c0d601c92fe3b4bcc5d23b5e30cef9c8"
    ["source/ai/server/Pledge44HFetcher.java"]="a93245cd8e1317ce9ef116b0c93e922de26d8efedb6472a06bc4ff0d45fb2453"
    ["source/ai/server/DiskAwarenessMonitor.java"]="42fffa3bca6c50b52177cea0a8f55cc6111a49bed1b817eed6f11aa147b83078"
    ["source/ai/module/TaxDefenseSpeculator.java"]="daf746e7cf925ecef5059b6b515e17219ce994e442d88b2a1eb989271d1793ed"
    ["source/ai/training/ConfigurationTrainer.java"]="eeb9c7ea537fe40e760e87eea53e8f1a4a49699b14254cfd22c27ea671e54b38"
    ["source/ai/training/WeightPersistence.java"]="17d7e3f127a77e2f0412bde3e5b7480c03a273af7a2a5fdfc7189337cf0e73ec"
    ["source/ai/trainers/TaxClosureTrainer.java"]="399b49fb49cd9c6930b10faeaaa7bdc91f2c7068f62e7c105d82ebe758e17426"
    ["source/ai/trainers/DefenseStrategyTrainer.java"]="0061e99fe4f3a525965759ecd0b04a8222db6ee36e7ac17741056c4ebcea16f1"
    ["source/ai/military/HardwareAndStrikes.java"]="2f37246c3f98737337e6c5435c0dc0cfaab225cc9759b6012c095ba281d1d1b2"
    ["source/ai/military/UptimeAccumulator.java"]="b7d1d414815e54f55a88a15553348ec4cd7e60de3fa6b8bee03b97f0b971bc20"
    ["source/pro/national/ConnectionGuard.java"]="2b8298fa6ca509d01e4cc4c77fc0ad89a7a50e10bda9df9be5f2a7be7cdd47a3"
    ["source/pro/national/ConsentGate.java"]="03f51c49929a6cf43f565456ffae801a47b69f6a3ada4ffa39fd5d9eb44307ec"
    ["source/pro/national/EjectionFuture.java"]="153bd508db79642d9fe53465df05d7dc8c9132476a0cbca2a58d1c39cd775485"
    ["source/pro/national/DueProcessPipeline.java"]="f406b57350312cdb9faab4f54eac9081260f4457a99781121fe69d7327cb70fb"
    ["source/pro/national/ParallelVetting.java"]="ae5e8eca8778d46f339a0bbab34db697373cc19cda3fc55139f7063044a34bf3"
    ["source/pro/national/ResponseDispatcher.java"]="76c506e9234ee73d884c35938a5f77199d5a04bb6c900770110c4cb161fb442c"
    ["source/pro/national/GracefulTransfer.java"]="436965d9ba4733f5fde6c99bb49c79e0b8a6079bcb699aed52d33bf2a59aea79"
    ["source/pro/national/LearningAccumulator.java"]="e6101fae20ab576e429ee121ae02b154c6c71e55581db838095ae92f45f88d0d"
    ["source/pro/national/CoolingCircuit.java"]="0d45a47217ef78d3af88c65d325b40ccbcd6d31f930d8664661b7eaee4b95853"
    ["configuration/ai-module-config.xml"]="9f4075fc1a0e79f83aa56043d0c48c24d0959527831029d967e7ea29493e5611"
    ["configuration/server-config.xml"]="e11d5926acb0bb723c01fcacb3e1c649a0149bb76bf1508ffc577aa3b6ca12b2"
    ["configuration/database-config.xml"]="6a2c0850f37451eeefa3cfa238de7232ccddae2dbd24fcd54674410cfe6dd89b"
    ["configuration/nwe-config.xml"]="01f4bb56c7da989aa3a8d31b4d204d4982601dea4188de3a6d00ae6a478dbe75"
    ["configuration/intent-regulator-config.xml"]="2ad2654ea61409cf239fcd2ad4795f1d2a31139745e445306b260dbedf9fbe1d"
    ["configuration/nio-masquerade-config.xml"]="f36852f7f03931044adab51bf31263c0f9f30a16d34c0b31bb154b71f5191419"
    ["configuration/blackbelt/hardware-and-strikes.xml"]="7a9f4a3fb92f8608380eecde2585319845c8c8ca0771a18ddb76fd61f2b21fc1"
    ["sql/schema.sql"]="2a0ecc3d6ffc41b75fc10454b5cdf9b3f4ac16fff7bbd6957ce0a326bc142dc8"
    ["sql/schema-update-ai.sql"]="dab4a4795efc6596e07253c894957eab1bfda2a8b24f282a3b64afe782168716"
    ["sql/schema-44h.sql"]="0c989bbcad36cf99938f1adda6391f9676ae1a3f61c411f048a28601003a48fb"
    ["bash/install.sh"]="e836d8bbb01a1dd310050871b2f5aeec5e355ad4b086d59afd324729045afca0"
    ["bash/start.sh"]="d1c6ab54dfa44ed416d78df3e427f2462d0a9376a940a9d42d6b5f2e9f1bc62b"
    ["bash/shutdown.sh"]="f1ca1bef43de1306f43e3607d78a73934e9feed463ad0038c70435e0536b581b"
    ["bash/test.sh"]="00910da5d8e77a2c26842f2c2a51ebd976b5986712aac7bb14dcaea83f3f7420"
    ["bash/test-qa.sh"]="d67825a46afd8565badbf8fd6e41f0bf2eea0a6858e684ba58d018c01eea1c47"
    ["bash/verify.sh"]="9e8d2cff118b039adca51880a7343b7db1cf648c4a85d10c20f1afde5303e1e9"
    ["bash/train.sh"]="0645ac2be5f71298fbff61cc5ac25664d46e1dd2929ef31fdd95c0870e9b3030"
)

# Verify against embedded baseline
TAMPERED=0
MISSING=0
VERIFIED=0

for FILE in "${CRITICAL_FILES[@]}"; do
    FULL="$PROJECT_DIR/$FILE"
    if [ ! -f "$FULL" ]; then
        echo "  ✗ MISSING: $FILE"
        echo "[$TIMESTAMP] TAMPER:MISSING $FILE" >> "$LOG_FILE"
        MISSING=$((MISSING + 1))
        continue
    fi

    ACTUAL_SUM=$(sha256sum "$FULL" | awk '{print $1}')
    EXPECTED_SUM="${BASELINE[$FILE]}"

    if [ "$EXPECTED_SUM" != "$ACTUAL_SUM" ]; then
        echo "  ✗ MODIFIED: $FILE"
        echo "[$TIMESTAMP] TAMPER:MODIFIED $FILE expected=$EXPECTED_SUM actual=$ACTUAL_SUM" >> "$LOG_FILE"
        TAMPERED=$((TAMPERED + 1))
    else
        echo "  ✓ OK: $FILE"
        VERIFIED=$((VERIFIED + 1))
    fi
done

echo ""
if [ "$TAMPERED" -eq 0 ] && [ "$MISSING" -eq 0 ]; then
    echo "  ✓ INTEGRITY VERIFIED — $VERIFIED/${#CRITICAL_FILES[@]} files clean, no tampering detected"
    echo "[$TIMESTAMP] INTEGRITY OK — $VERIFIED files verified" >> "$LOG_FILE"
else
    echo "  ✗ INTEGRITY VIOLATION — $TAMPERED modified, $MISSING missing (of ${#CRITICAL_FILES[@]} monitored)"
    echo "[$TIMESTAMP] VIOLATION tampered=$TAMPERED missing=$MISSING verified=$VERIFIED" >> "$LOG_FILE"
fi

echo ""
echo "  Log: $LOG_FILE"
exit $((TAMPERED + MISSING))
