<#
.SYNOPSIS
    Downloads the PF Concept data feeds (Windows).
.DESCRIPTION
    Fetches the configured JSON feeds from pfconcept.com and saves each locally,
    derived from the URL's filename. Each download goes to a temp file and is
    validated as JSON before replacing the existing copy, which is kept as a .bak
    backup. One feed failing does not stop the others.
#>

[CmdletBinding()]
param(
    [string[]]$Urls = @(
        'https://www.pfconcept.com/portal/datafeed/printdata_cse1_fi_v3.json',
        'https://www.pfconcept.com/portal/datafeed/productfeed_en_v3.json'
    ),
    [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$failed = 0

foreach ($url in $Urls) {
    $fileName = [System.IO.Path]::GetFileName(([System.Uri]$url).AbsolutePath)
    $outFile  = Join-Path $OutDir $fileName
    $tempFile = "$outFile.tmp"

    Write-Host "Downloading $url ..."

    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

        # Basic sanity check: ensure the downloaded content is valid JSON.
        Get-Content -Raw -Path $tempFile | ConvertFrom-Json | Out-Null

        if (Test-Path $outFile) {
            Copy-Item -Path $outFile -Destination "$outFile.bak" -Force
        }

        Move-Item -Path $tempFile -Destination $outFile -Force

        $size = (Get-Item $outFile).Length
        Write-Host "Saved $outFile ($size bytes)." -ForegroundColor Green
    }
    catch {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        Write-Error "Download failed for ${url}: $($_.Exception.Message)"
        $failed++
    }
}

if ($failed -gt 0) {
    Write-Error "$failed feed(s) failed to download."
    exit 1
}
