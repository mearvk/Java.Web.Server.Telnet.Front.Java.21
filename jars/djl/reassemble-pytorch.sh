#!/bin/bash
# Reassembles pytorch-native-cpu-2.5.1-linux-x86_64.jar from split parts if not already present
DIR="$(cd "$(dirname "$0")" && pwd)"
JAR="$DIR/pytorch-native-cpu-2.5.1-linux-x86_64.jar"

if [ -f "$JAR" ]; then
    exit 0
fi

cat "$DIR/native_pytorch_cpu_linux_x86_64_aa" "$DIR/native_pytorch_cpu_linux_x86_64_ab" > "$JAR"
echo "Reassembled pytorch-native-cpu-2.5.1-linux-x86_64.jar"
