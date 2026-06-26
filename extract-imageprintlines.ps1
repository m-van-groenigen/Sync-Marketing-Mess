<#
.SYNOPSIS
    Extracts every .jpg filename from the "imagePrintLine" fields in the PF Concept
    print feed and writes a unique, sorted list to a text file.

.DESCRIPTION
    The feed is a single huge minified JSON line, so this script does NOT load the
    whole document into memory. It streams the file through a fixed-size character
    buffer (with a small overlap so tokens are never split across chunk boundaries)
    and matches "imagePrintLine":"..." occurrences with a regex. Only the set of
    distinct filenames is held in memory (a few thousand short strings).

.EXAMPLE
    ./extract-imageprintlines.ps1
    ./extract-imageprintlines.ps1 -JsonPath feed.json -OutFile images.txt
#>

[CmdletBinding()]
param(
    [string]$JsonPath = (Join-Path $PSScriptRoot 'printdata_cse1_fi_v3.json'),
    [string]$OutFile  = (Join-Path $PSScriptRoot 'imageprintlines.txt'),
    [int]$BufferSize  = 65536
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $JsonPath)) {
    throw "Input JSON not found: $JsonPath"
}

# Matches:  "imagePrintLine":"<value>"  (tolerant of whitespace around the colon).
# Group 1 is the raw JSON string value (no escaped quotes occur in these filenames).
$regex = [System.Text.RegularExpressions.Regex]::new(
    '"imagePrintLine"\s*:\s*"([^"\\]*)"',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

# Overlap kept between chunks so a token straddling a boundary is still matched
# on the next read. Must exceed the longest possible "imagePrintLine":"..." token.
$overlap = 256

$set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

$reader = [System.IO.StreamReader]::new($JsonPath, [System.Text.Encoding]::UTF8)
try {
    $buffer  = [char[]]::new($BufferSize)
    $carry   = ''
    while (($read = $reader.Read($buffer, 0, $BufferSize)) -gt 0) {
        $chunk = $carry + [string]::new($buffer, 0, $read)

        foreach ($m in $regex.Matches($chunk)) {
            $value = $m.Groups[1].Value
            if ($value) {
                # Decode the only JSON escape that appears in paths.
                if ($value.IndexOf('\') -ge 0) { $value = $value.Replace('\/', '/') }
                [void]$set.Add($value)
            }
        }

        # Retain the tail so a split token is recombined with the next chunk.
        if ($chunk.Length -gt $overlap) {
            $carry = $chunk.Substring($chunk.Length - $overlap)
        } else {
            $carry = $chunk
        }
    }
}
finally {
    $reader.Dispose()
}

# Unique + sorted (ordinal) output.
$sorted = [System.Linq.Enumerable]::ToArray($set)
[System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)

[System.IO.File]::WriteAllLines($OutFile, $sorted, [System.Text.Encoding]::UTF8)

Write-Host "Wrote $($sorted.Count) unique imagePrintLine entries to $OutFile" -ForegroundColor Green
