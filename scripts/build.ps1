param([Parameter(Mandatory=$true)][string]$Version)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Expected X.Y.Z' }
$toc = Get-Content (Join-Path $root 'GAPerGuide/GAPerGuide.toc') -Raw
if ($toc -notmatch "(?m)^## Version:\s*$([regex]::Escape($Version))\s*$") { throw 'Tag and TOC versions differ' }
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
Compress-Archive -Path (Join-Path $root 'GAPerGuide') -DestinationPath (Join-Path $dist 'GAPerGuide.zip') -Force
Compress-Archive -Path (Join-Path $root 'updater') -DestinationPath (Join-Path $dist 'GAPerUpdater.zip') -Force
$lines = foreach ($name in @('GAPerGuide.zip','GAPerUpdater.zip')) {
    $hash = (Get-FileHash (Join-Path $dist $name) -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $name"
}
$lines | Set-Content (Join-Path $dist 'SHA256SUMS.txt') -Encoding ascii
