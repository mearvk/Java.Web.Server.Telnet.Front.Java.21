#!/bin/bash
echo "--- Installing JARs ---"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JARS_DIR="$SCRIPT_DIR/../jars"
mkdir -p "$JARS_DIR"

curl -L -s -o "$JARS_DIR/jdsp-3.1.1.jar" "https://repo1.maven.org/maven2/com/github/psambit9791/jdsp/3.1.1/jdsp-3.1.1.jar"
echo "  Downloaded jdsp-3.1.1.jar"

curl -L -s -o "$JARS_DIR/jscipy-3.1.7.jar" "https://repo1.maven.org/maven2/io/github/hissain/jscipy/3.1.7/jscipy-3.1.7.jar"
echo "  Downloaded jscipy-3.1.7.jar"

curl -L -s -o "$JARS_DIR/TarsosDSP-core-2.5.jar" "https://mvn.0110.be/releases/be/tarsos/dsp/core/2.5/core-2.5.jar"
echo "  Downloaded TarsosDSP-core-2.5.jar"

curl -L -s -o "$JARS_DIR/TarsosDSP-jvm-2.5.jar" "https://mvn.0110.be/releases/be/tarsos/dsp/jvm/2.5/jvm-2.5.jar"
echo "  Downloaded TarsosDSP-jvm-2.5.jar"

curl -L -s -o "$JARS_DIR/commons-math3-3.6.1.jar" "https://repo1.maven.org/maven2/org/apache/commons/commons-math3/3.6.1/commons-math3-3.6.1.jar"
echo "  Downloaded commons-math3-3.6.1.jar"

curl -L -s -o "$JARS_DIR/mysql-connector-j-8.3.0.jar" "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"
echo "  Downloaded mysql-connector-j-8.3.0.jar"

echo "JARs installed:"
ls "$JARS_DIR"/*.jar 2>/dev/null
