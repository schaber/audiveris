#!/usr/bin/env bash
# Run Audiveris in batch mode on a PDF/image: transcribe, export MusicXML, print engraved PDF.
#
# Usage: dev/sandbox/run.sh <input.pdf> <output-dir> [sheet ids...]
#   e.g. dev/sandbox/run.sh score.pdf out 2 5-15
#
# Sheet ids are optional. Use them to skip cover pages or sheets that crash OMR:
# any failing sheet aborts the whole batch export.
set -euo pipefail

if [ $# -lt 2 ]; then
    sed -n 2,8p "$0"
    exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
INPUT="$(realpath "$1")"
OUTPUT="$(realpath -m "$2")"
shift 2

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
export TESSDATA_PREFIX="${TESSDATA_DIR:-$HOME/.audiveris-tessdata}"

SHEETS=()
if [ $# -gt 0 ]; then
    SHEETS=(-sheets "$@")
fi

mkdir -p "$OUTPUT"
"$REPO_DIR/app/build/install/app/bin/Audiveris" -batch "${SHEETS[@]}" \
    -transcribe -export -print -output "$OUTPUT" -- "$INPUT" 2>&1 | tee "$OUTPUT/run.log"

echo
grep -E "Printed sheet|exported to|Error processing stub|Exit forced" "$OUTPUT/run.log" || true
