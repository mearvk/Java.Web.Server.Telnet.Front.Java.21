#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"

mvn -B clean package
mkdir -p dist
APP_VERSION=$(mvn -q -DforceStdout help:evaluate -Dexpression=project.version)
JAR="target/us-house-installer-${APP_VERSION}.jar"

if [ ! -f "$JAR" ]; then
  echo "Build did not produce $JAR" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    jpackage --type dmg --name US-House-Installer --input target --main-jar "$(basename "$JAR")" --main-class us.house.installer.USHouseInstaller --dest dist
    ;;
  Linux)
    jpackage --type deb --name us-house-installer --input target --main-jar "$(basename "$JAR")" --main-class us.house.installer.USHouseInstaller --dest dist
    ;;
  *)
    echo "Use build-native.ps1 on Windows." >&2
    exit 2
    ;;
esac

echo "Native installer written to $ROOT/dist"
