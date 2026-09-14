#!/bin/bash
# train.sh — On-demand training for Democratic AI and BlackBelt modules
# Installer ID: MEARVK LLC — Max Rupplin
# D500 Democratic President

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
CLASSPATH="$PROJECT_DIR/source:$PROJECT_DIR/jars/*"

echo "═══════════════════════════════════════════════════════════════"
echo " Democratic AI & BlackBelt™ — On-Demand Training"
echo " $(date)"
echo "═══════════════════════════════════════════════════════════════"

MODULE="${1:-all}"

train_democratic() {
    echo ""
    echo "── Training Democratic AI (ConfigurationTrainer) ──"
    java -cp "$CLASSPATH" ai.training.ConfigurationTrainer
    echo "[train.sh] Democratic AI training complete."
}

train_blackbelt() {
    echo ""
    echo "── Training BlackBelt™ (Ethics Model) ──"
    # BlackBelt trains from the ethics subset within ConfigurationTrainer
    java -cp "$CLASSPATH" -Dtrain.module=blackbelt ai.training.ConfigurationTrainer
    echo "[train.sh] BlackBelt™ training complete."
}

case "$MODULE" in
    democratic)
        train_democratic
        ;;
    blackbelt)
        train_blackbelt
        ;;
    all)
        train_democratic
        train_blackbelt
        ;;
    *)
        echo "Usage: bash train.sh [democratic|blackbelt|all]"
        exit 1
        ;;
esac

echo ""
echo "── Training weights saved to: training/weights/ ──"
echo "═══════════════════════════════════════════════════════════════"
