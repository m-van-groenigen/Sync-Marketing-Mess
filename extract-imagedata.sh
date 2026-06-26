#!/usr/bin/env bash
#
# Extracts every image filename from the "imageData" blocks in the PF Concept
# product feed and writes a unique, sorted list (one filename per line).
#
# The product feed is large (~189 MB), so this does NOT load the whole document
# into memory. It uses grep -o to stream-match the fixed set of imageData slot
# keys (imageMain, imageFront, ...), which occur only inside imageData, then
# dedupes and sorts. Only the result set is held in memory.
#
# Tested on CentOS Stream 9 (GNU grep / coreutils).
#
# Usage:
#   ./extract-imagedata.sh
#   ./extract-imagedata.sh <json-path> <out-file>

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_PATH="${1:-$SCRIPT_DIR/productfeed_en_v3.json}"
OUTFILE="${2:-$SCRIPT_DIR/imageData_filenames.txt}"

if [ ! -f "$JSON_PATH" ]; then
    echo "Input JSON not found: $JSON_PATH" >&2
    exit 1
fi

# Fixed set of imageData slot keys (each appears only inside imageData).
KEYS='imageMain|imageLogoY[123]|imagePackage|imageFront|imageBack|imageExtra[123]|imageDetail[123]|imageGroup|imageMood[123]|imageModel'

# Stream the file:
#   grep -oE        : print only the matched "<key>":"value" tokens
#   sed             : strip the key/quotes, keep the value
#   grep -v '^$'    : drop empty values
#   sort -u         : unique + sorted (C locale for deterministic byte order)
LC_ALL=C grep -oE "\"($KEYS)\"[[:space:]]*:[[:space:]]*\"[^\"\\]*\"" "$JSON_PATH" \
    | sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"(.*)"$/\1/' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | grep -v '^$' \
    | LC_ALL=C sort -u > "$OUTFILE"

COUNT=$(wc -l < "$OUTFILE" | tr -d ' ')
echo "Wrote $COUNT unique imageData filenames to $OUTFILE"
