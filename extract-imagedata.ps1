<#
.SYNOPSIS
    Extracts every image filename from the "imageData" blocks in the PF Concept
    product feed and writes a unique, sorted list (one filename per line).

.DESCRIPTION
    The product feed is large (~189 MB), so this script streams it through a
    fixed-size character buffer (with a small overlap so tokens are never split
    across chunk boundaries) instead of loading the whole document into memory.
    It matches the fixed set of imageData slot keys (imageMain, imageFront, ...),
    which occur only inside imageData, and collects their non-empty values.

.EXAMPLE
    ./extract-imagedata.ps1
    ./extract-imagedata.ps1 -JsonPath productfeed_en_v3.json -OutFile images.txt
#>

[CmdletBinding()]
param(
    [string]$JsonPath = (Join-Path $PSScriptRoot 'productfeed_en_v3.json'),
    [string]$OutFile  = (Join-Path $PSScriptRoot 'imagedata_filenames.txt'),
    [int]$BufferSize  = 131072
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $JsonPath)) {
    throw "Input JSON not found: $JsonPath"
}

# Fixed set of imageData slot keys (each appears only inside imageData).
$regex = [System.Text.RegularExpressions.Regex]::new(
    '"(?:imageMain|imageLogoY[123]|imagePackage|imageFront|imageBack|imageExtra[123]|imageDetail[123]|imageGroup|imageMood[123]|imageModel)"\s*:\s*"([^"\\]*)"',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

# Overlap kept between chunks so a token straddling a boundary is still matched.
$overlap = 256

$set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

$reader = [System.IO.StreamReader]::new($JsonPath, [System.Text.Encoding]::UTF8)
try {
    $buffer = [char[]]::new($BufferSize)
    $carry  = ''
    while (($read = $reader.Read($buffer, 0, $BufferSize)) -gt 0) {
        $chunk = $carry + [string]::new($buffer, 0, $read)

        foreach ($m in $regex.Matches($chunk)) {
            $value = $m.Groups[1].Value
            if ($value) { [void]$set.Add($value.Trim()) }
        }

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

Write-Host "Wrote $($sorted.Count) unique imageData filenames to $OutFile" -ForegroundColor Green
