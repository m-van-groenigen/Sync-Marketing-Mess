#!/usr/bin/env bash
#
# scanmissing-imagedata.sh
#
# For every target/source pair listed in imagedata_locations.csv, check whether
# each filename in imagedata_filenames.txt exists in the target directory.
# Report any missing file, and also report whether it exists in the source dir.
# With --fix, copy the file from source to target when it is missing from target
# but present in source.
#
# Tested on CentOS Stream 9.
#
# Usage:
#   ./scanmissing-imagedata.sh [--fix] [--verbose] [csv-file] [filelist]
#
#   --fix        copy source -> target for files missing in target
#   --verbose    also report files that ARE present in target (with size)
#   csv-file     default: imagedata_locations.csv  (columns: type,target,source)
#   filelist     default: imagedata_filenames.txt  (one filename per line)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FIX=0
VERBOSE=0
POSARGS=()
for arg in "$@"; do
    case "$arg" in
        --fix) FIX=1 ;;
        --verbose) VERBOSE=1 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --*)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
        *) POSARGS+=("$arg") ;;
    esac
done

CSV="${POSARGS[0]:-$SCRIPT_DIR/imagedata_locations.csv}"
LIST="${POSARGS[1]:-$SCRIPT_DIR/imagedata_filenames.txt}"

if [ ! -f "$CSV" ];  then echo "CSV not found: $CSV" >&2;  exit 1; fi
if [ ! -f "$LIST" ]; then echo "File list not found: $LIST" >&2; exit 1; fi

if [ "$FIX" -eq 1 ]; then
    echo "Mode: FIX (missing files will be copied source -> target)"
else
    echo "Mode: REPORT only (run with --fix to copy missing files)"
fi

echo "CSV:  $CSV"
echo "List: $LIST"
list_bytes=$(wc -c < "$LIST" | tr -d ' ')
list_lines=$(wc -l < "$LIST" | tr -d ' ')
echo "List size: $list_bytes bytes, $list_lines lines"

# Totals across all targets.
grand_checked=0
grand_missing=0
grand_in_source=0
grand_not_in_source=0
grand_fixed=0
grand_fix_failed=0

# Read the CSV, skipping the header row.
first_line=1
while IFS=',' read -r type target source _rest || [ -n "${type:-}" ]; do
    # Skip header.
    if [ "$first_line" -eq 1 ]; then first_line=0; continue; fi
    # Skip blank lines.
    [ -z "${type:-}" ] && [ -z "${target:-}" ] && continue

    # Trim possible surrounding whitespace / carriage returns.
    target="$(printf '%s' "$target" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    source="$(printf '%s' "$source" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

    echo
    echo "==================================================================="
    echo "Target: $target"
    echo "Source: $source"
    echo "-------------------------------------------------------------------"

    if [ ! -d "$target" ]; then
        echo "  WARNING: target directory does not exist."
    fi
    if [ ! -d "$source" ]; then
        echo "  WARNING: source directory does not exist."
    fi

    if [ "$FIX" -eq 1 ]; then
        mkdir -p "$target"
    fi

    missing=0
    checked=0
    in_source=0
    not_in_source=0
    fixed=0
    fix_failed=0

    while IFS= read -r fname || [ -n "$fname" ]; do
        fname="${fname%$'\r'}"
        [ -z "$fname" ] && continue
        checked=$((checked + 1))

        if [ -e "$target/$fname" ]; then
            if [ "$VERBOSE" -eq 1 ]; then
                fsize=$(wc -c < "$target/$fname" 2>/dev/null | tr -d ' ')
                echo "  FOUND: $fname ($fsize bytes)"
            fi
            continue
        fi

        missing=$((missing + 1))

        if [ -e "$source/$fname" ]; then
            in_source=$((in_source + 1))
            if [ "$FIX" -eq 1 ]; then
                if /bin/cp -p "$source/$fname" "$target/$fname" 2>/dev/null; then
                    fixed=$((fixed + 1))
                    echo "  MISSING (copied from source): $fname"
                else
                    fix_failed=$((fix_failed + 1))
                    echo "  MISSING (in source, COPY FAILED): $fname"
                fi
            else
                echo "  MISSING (available in source): $fname"
            fi
        else
            not_in_source=$((not_in_source + 1))
            echo "  MISSING (NOT in source): $fname"
        fi
    done < "$LIST"

    echo "-------------------------------------------------------------------"
    if [ "$FIX" -eq 1 ]; then
        echo "  Summary: scanned=$checked  present=$((checked - missing))  missing=$missing  copied=$fixed  copy_failed=$fix_failed  not_in_source=$not_in_source"
    else
        echo "  Summary: scanned=$checked  present=$((checked - missing))  missing=$missing  in_source=$in_source  not_in_source=$not_in_source"
    fi

    grand_checked=$((grand_checked + checked))
    grand_missing=$((grand_missing + missing))
    grand_in_source=$((grand_in_source + in_source))
    grand_not_in_source=$((grand_not_in_source + not_in_source))
    grand_fixed=$((grand_fixed + fixed))
    grand_fix_failed=$((grand_fix_failed + fix_failed))
done < "$CSV"

echo
echo "==================================================================="
echo "TOTAL"
if [ "$FIX" -eq 1 ]; then
    echo "  scanned=$grand_checked  present=$((grand_checked - grand_missing))  missing=$grand_missing  copied=$grand_fixed  copy_failed=$grand_fix_failed  not_in_source=$grand_not_in_source"
else
    echo "  scanned=$grand_checked  present=$((grand_checked - grand_missing))  missing=$grand_missing  in_source=$grand_in_source  not_in_source=$grand_not_in_source"
fi

# Non-zero exit if anything is still unresolved (missing and not fixable).
if [ "$grand_not_in_source" -gt 0 ] || [ "$grand_fix_failed" -gt 0 ]; then
    exit 1
fi
exit 0
