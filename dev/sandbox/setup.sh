#!/usr/bin/env bash
# Build Audiveris in a fresh Ubuntu 24.04 sandbox (e.g. a Claude Code cloud session).
# Idempotent: safe to re-run.
#
# Usage: dev/sandbox/setup.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESSDATA_DIR="${TESSDATA_DIR:-$HOME/.audiveris-tessdata}"
JDK_HOME=/usr/lib/jvm/java-25-openjdk-amd64

# 1. JDK 25 (the build requires source release 25) + Tesseract + PDF tools
if [ ! -x "$JDK_HOME/bin/javac" ] || ! command -v tesseract >/dev/null; then
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        openjdk-25-jdk-headless tesseract-ocr poppler-utils >/dev/null
fi

# 2. Full Tesseract 'eng' model.
#    Ubuntu's eng.traineddata is LSTM-only; Audiveris needs the legacy engine too.
if [ ! -s "$TESSDATA_DIR/eng.traineddata" ]; then
    mkdir -p "$TESSDATA_DIR"
    curl -sSL -o "$TESSDATA_DIR/eng.traineddata" \
        https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/eng.traineddata
fi

# 3. Empty stub for javax.media:jai-core:1.1.3.
#    It is only served by repository.jboss.org (often blocked by sandbox proxies)
#    and no Audiveris source actually imports javax.media.jai.
STUB="$HOME/.m2/repository/javax/media/jai-core/1.1.3"
if [ ! -s "$STUB/jai-core-1.1.3.pom" ]; then
    mkdir -p "$STUB"
    EMPTY="$(mktemp -d)"
    "$JDK_HOME/bin/jar" cf "$STUB/jai-core-1.1.3.jar" -C "$EMPTY" .
    rmdir "$EMPTY"
    cat > "$STUB/jai-core-1.1.3.pom" <<'EOF'
<project><modelVersion>4.0.0</modelVersion><groupId>javax.media</groupId><artifactId>jai-core</artifactId><version>1.1.3</version></project>
EOF
fi

# 4. Build. Retries cover Maven Central HTTP 429 rate limiting.
cd "$REPO_DIR"
export JAVA_HOME="$JDK_HOME"
for i in 1 2 3 4; do
    if ./gradlew -q :app:installDist; then
        break
    fi
    [ "$i" = 4 ] && { echo "Build failed" >&2; exit 1; }
    sleep $((i * 15))
done

echo "Built: $REPO_DIR/app/build/install/app/bin/Audiveris"
echo "Tessdata: $TESSDATA_DIR"
