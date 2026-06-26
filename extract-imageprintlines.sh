#!/usr/bin/env bash
#
# Extracts every .jpg filename from the "imagePrintLine" fields in the PF Concept
# print feed and writes a unique, sorted list to a text file (one per line).
#
# The feed is a single huge minified JSON line, so this does NOT load the whole
# document into memory. It uses grep -o to stream-match the "imagePrintLine":"..."
# tokens, then dedupes and sorts. Only the result set is held in memory.
#
# Tested on CentOS Stream 9 (GNU grep / coreutils).
#
# Usage:
#   ./extract-imageprintlines.sh
#   ./extract-imageprintlines.sh <json-path> <out-file>

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_PATH="${1:-$SCRIPT_DIR/printdata_cse1_fi_v3.json}"
OUTFILE="${2:-$SCRIPT_DIR/imagePrintLines.txt}"

if [ ! -f "$JSON_PATH" ]; then
    echo "Input JSON not found: $JSON_PATH" >&2
    exit 1
fi

# Stream the file:
#   grep -oE        : print only the matched "imagePrintLine":"value" tokens
#   sed             : strip the key/quotes, keep the value, decode JSON \/ to /
#   grep -v '^$'    : drop empty values
#   sort -u         : unique + sorted (C locale for deterministic byte order)
LC_ALL=C grep -oE '"imagePrintLine"[[:space:]]*:[[:space:]]*"[^"\\]*"' "$JSON_PATH" \
    | sed -E 's/^"imagePrintLine"[[:space:]]*:[[:space:]]*"(.*)"$/\1/; s#\\/#/#g' \
    | grep -v '^$' \
    | LC_ALL=C sort -u > "$OUTFILE"

COUNT=$(wc -l < "$OUTFILE" | tr -d ' ')
echo "Wrote $COUNT unique imagePrintLine entries to $OUTFILE"
