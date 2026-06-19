#!/usr/bin/env bash
# download-djl.sh — Download Deep Java Library (DJL) jars for Strernary inference
# DJL is Amazon's open-source Java framework for deep learning inference.
# https://github.com/deepjavalibrary/djl
#
# Places jars in jars/djl/ for classpath inclusion.

set -e

DJL_VERSION="0.31.0"
TARGET_DIR="$(dirname "$0")/../../../jars/djl"

mkdir -p "$TARGET_DIR"

MAVEN_BASE="https://repo1.maven.org/maven2"

JARS=(
    "ai/djl/api/${DJL_VERSION}/api-${DJL_VERSION}.jar"
    "ai/djl/basicdataset/${DJL_VERSION}/basicdataset-${DJL_VERSION}.jar"
    "ai/djl/model-zoo/${DJL_VERSION}/model-zoo-${DJL_VERSION}.jar"
    "ai/djl/pytorch/pytorch-engine/${DJL_VERSION}/pytorch-engine-${DJL_VERSION}.jar"
    "ai/djl/pytorch/pytorch-model-zoo/${DJL_VERSION}/pytorch-model-zoo-${DJL_VERSION}.jar"
    "ai/djl/huggingface/tokenizers/${DJL_VERSION}/tokenizers-${DJL_VERSION}.jar"
)

echo "[Strernary] Downloading DJL ${DJL_VERSION} jars to ${TARGET_DIR}..."

for JAR_PATH in "${JARS[@]}"; do
    FILENAME=$(basename "$JAR_PATH")
    if [ -f "${TARGET_DIR}/${FILENAME}" ]; then
        echo "  [SKIP] ${FILENAME} already exists."
    else
        echo "  [GET]  ${FILENAME}..."
        wget -q -O "${TARGET_DIR}/${FILENAME}" "${MAVEN_BASE}/${JAR_PATH}" || {
            echo "  [WARN] Failed to download ${FILENAME}. Continuing..."
            rm -f "${TARGET_DIR}/${FILENAME}"
        }
    fi
done

echo "[Strernary] DJL download complete. Add jars/djl/*.jar to classpath."
echo "[Strernary] Native PyTorch libs will auto-download on first inference run."
