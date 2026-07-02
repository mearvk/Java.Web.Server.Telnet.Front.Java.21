#!/bin/bash
echo "--- Downloading AI/ML JARs ---"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JARS_DIR="$SCRIPT_DIR/../jars/ai"
mkdir -p "$JARS_DIR"

DJL_VER="0.36.0"

curl -L -s -o "$JARS_DIR/djl-api-$DJL_VER.jar" "https://repo1.maven.org/maven2/ai/djl/api/$DJL_VER/api-$DJL_VER.jar"
echo "  Downloaded djl-api-$DJL_VER.jar"

curl -L -s -o "$JARS_DIR/pytorch-engine-$DJL_VER.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-engine/$DJL_VER/pytorch-engine-$DJL_VER.jar"
echo "  Downloaded pytorch-engine-$DJL_VER.jar"

curl -L -s -o "$JARS_DIR/pytorch-native-auto-2.7.1.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-native-auto/2.7.1/pytorch-native-auto-2.7.1.jar"
echo "  Downloaded pytorch-native-auto-2.7.1.jar"

curl -L -s -o "$JARS_DIR/pytorch-jni-2.7.1-$DJL_VER.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-jni/2.7.1-$DJL_VER/pytorch-jni-2.7.1-$DJL_VER.jar"
echo "  Downloaded pytorch-jni-2.7.1-$DJL_VER.jar"

curl -L -s -o "$JARS_DIR/model-zoo-$DJL_VER.jar" "https://repo1.maven.org/maven2/ai/djl/model-zoo/$DJL_VER/model-zoo-$DJL_VER.jar"
echo "  Downloaded model-zoo-$DJL_VER.jar"

curl -L -s -o "$JARS_DIR/basicdataset-$DJL_VER.jar" "https://repo1.maven.org/maven2/ai/djl/basicdataset/$DJL_VER/basicdataset-$DJL_VER.jar"
echo "  Downloaded basicdataset-$DJL_VER.jar"

curl -L -s -o "$JARS_DIR/onnxruntime-engine-$DJL_VER.jar" "https://repo1.maven.org/maven2/ai/djl/onnxruntime/onnxruntime/$DJL_VER/onnxruntime-$DJL_VER.jar"
echo "  Downloaded onnxruntime-engine-$DJL_VER.jar"

curl -L -s -o "$JARS_DIR/onnxruntime-1.19.2.jar" "https://repo1.maven.org/maven2/com/microsoft/onnxruntime/onnxruntime/1.19.2/onnxruntime-1.19.2.jar"
echo "  Downloaded onnxruntime-1.19.2.jar"

# Platform-specific native PyTorch
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  Downloading PyTorch native (macOS aarch64 - ~70MB)..."
    curl -L -s -o "$JARS_DIR/pytorch-native-cpu-2.7.1-osx-aarch64.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-native-cpu/2.7.1/pytorch-native-cpu-2.7.1-osx-aarch64.jar"
else
    echo "  Downloading PyTorch native (Linux x86_64 - ~75MB)..."
    curl -L -s -o "$JARS_DIR/pytorch-native-cpu-2.7.1-linux-x86_64.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-native-cpu/2.7.1/pytorch-native-cpu-2.7.1-linux-x86_64.jar"
fi

curl -L -s -o "$JARS_DIR/gson-2.11.0.jar" "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.11.0/gson-2.11.0.jar"
echo "  Downloaded gson-2.11.0.jar"

curl -L -s -o "$JARS_DIR/slf4j-api-2.0.16.jar" "https://repo1.maven.org/maven2/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar"
echo "  Downloaded slf4j-api-2.0.16.jar"

curl -L -s -o "$JARS_DIR/slf4j-simple-2.0.16.jar" "https://repo1.maven.org/maven2/org/slf4j/slf4j-simple/2.0.16/slf4j-simple-2.0.16.jar"
echo "  Downloaded slf4j-simple-2.0.16.jar"

echo
echo "AI JARs installed:"
ls -lh "$JARS_DIR"/*.jar
