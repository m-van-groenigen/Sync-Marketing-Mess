#!/usr/bin/env bash
#
# Downloads the PF Concept data feeds (Linux/macOS).
# Fetches the configured JSON feeds from pfconcept.com and saves each locally,
# derived from the URL's filename. Each download goes to a temp file and is
# validated as JSON (when jq is present) before replacing the existing copy,
# which is kept as a .bak backup. One feed failing does not stop the others.

set -uo pipefail

# Feed URLs to download. Override by passing URLs as arguments.
if [ "$#" -gt 0 ]; then
    URLS=("$@")
else
    URLS=(
        "https://www.pfconcept.com/portal/datafeed/printdata_cse1_fi_v3.json"
        "https://www.pfconcept.com/portal/datafeed/productfeed_en_v3.json"
    )
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

download_feed() {
    local url="$1"
    local outfile="$SCRIPT_DIR/$(basename "${url%%\?*}")"
    local tmpfile="$outfile.tmp"

    echo "Downloading $url ..."

    if command -v curl >/dev/null 2>&1; then
        curl -fSL "$url" -o "$tmpfile" || return 1
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$tmpfile" || return 1
    else
        echo "Error: neither curl nor wget is installed." >&2
        return 1
    fi

    # Basic sanity check: ensure the downloaded content is valid JSON (if jq is available).
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$tmpfile" >/dev/null 2>&1; then
            echo "Error: $url did not return valid JSON." >&2
            rm -f "$tmpfile"
            return 1
        fi
    fi

    [ -f "$outfile" ] && cp -f "$outfile" "$outfile.bak"
    mv -f "$tmpfile" "$outfile"

    local size
    size=$(wc -c < "$outfile" | tr -d ' ')
    echo "Saved $outfile ($size bytes)."
}

for url in "${URLS[@]}"; do
    if ! download_feed "$url"; then
        echo "Download failed for $url" >&2
        FAILED=$((FAILED + 1))
    fi
done

if [ "$FAILED" -gt 0 ]; then
    echo "$FAILED feed(s) failed to download." >&2
    exit 1
fi
