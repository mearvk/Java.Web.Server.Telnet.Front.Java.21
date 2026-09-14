#!/usr/bin/env bash
# download-search-engine.sh — Download Google API Client jars for CityAnalysis search
# Uses Google Custom Search JSON API for real estate / lending practice queries.
#
# Places jars in jars/google-search/ for classpath inclusion.

set -e

TARGET_DIR="$(dirname "$0")/../../../jars/google-search"

mkdir -p "$TARGET_DIR"

MAVEN_BASE="https://repo1.maven.org/maven2"

# Google API Client for Java - pinned versions
GOOGLE_API_CLIENT_VERSION="2.7.2"
GOOGLE_SEARCH_VERSION="v1-rev20240821-2.0.0"
GOOGLE_HTTP_VERSION="1.45.3"
JACKSON_VERSION="2.18.2"

JARS=(
    "com/google/api-client/google-api-client/${GOOGLE_API_CLIENT_VERSION}/google-api-client-${GOOGLE_API_CLIENT_VERSION}.jar"
    "com/google/apis/google-api-services-customsearch/${GOOGLE_SEARCH_VERSION}/google-api-services-customsearch-${GOOGLE_SEARCH_VERSION}.jar"
    "com/google/http-client/google-http-client/${GOOGLE_HTTP_VERSION}/google-http-client-${GOOGLE_HTTP_VERSION}.jar"
    "com/google/http-client/google-http-client-jackson2/${GOOGLE_HTTP_VERSION}/google-http-client-jackson2-${GOOGLE_HTTP_VERSION}.jar"
    "com/google/http-client/google-http-client-gson/${GOOGLE_HTTP_VERSION}/google-http-client-gson-${GOOGLE_HTTP_VERSION}.jar"
    "com/fasterxml/jackson/core/jackson-core/${JACKSON_VERSION}/jackson-core-${JACKSON_VERSION}.jar"
    "com/google/code/gson/gson/2.11.0/gson-2.11.0.jar"
    "com/google/oauth-client/google-oauth-client/1.36.0/google-oauth-client-1.36.0.jar"
    "io/opencensus/opencensus-api/0.31.1/opencensus-api-0.31.1.jar"
    "io/opencensus/opencensus-contrib-http-util/0.31.1/opencensus-contrib-http-util-0.31.1.jar"
)

echo "[CityAnalysis] Downloading Google Search API jars to ${TARGET_DIR}..."

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

echo "[CityAnalysis] Google Search API download complete."
echo "[CityAnalysis] Set your API key and CX in city-analysis-config.xml <search-engine> section."
