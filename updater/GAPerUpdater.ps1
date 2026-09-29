param([switch]$LaunchBattleNet, [switch]$NoPause)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "GAPer Updater"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir "config.json"

function Pause-End {
    Write-Host ""
    if (!$NoPause) { Read-Host "Press Enter to close" | Out-Null }
}

try {
    if (!(Test-Path $ConfigPath)) {
        throw "config.json not found."
    }

    $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $repo = [string]$cfg.github_repo
    $addonName = [string]$cfg.addon_folder_name
    $wowPath = [string]$cfg.wow_path
    $assetName = [string]$cfg.release_asset_name

    if ([string]::IsNullOrWhiteSpace($repo) -or $repo -notmatch "^[^/]+/[^/]+$") {
        throw "Invalid github_repo in config.json. Expected owner/repo."
    }

    if ($repo -ne 'gaperforever/GAPer-Forever' -or $addonName -ne 'GAPerGuide' -or $assetName -ne 'GAPerGuide.zip') { throw 'Unexpected repository or addon configuration.' }
    $wowPath = [IO.Path]::GetFullPath($wowPath)
    $addonsDir = Join-Path $wowPath "Interface\AddOns"
    $targetDir = Join-Path $addonsDir $addonName

    Write-Host "========================================" -ForegroundColor DarkYellow
    Write-Host " GAPer Updater" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor DarkYellow
    Write-Host "Repository: $repo"
    Write-Host "WoW:        $wowPath"
    Write-Host ""

    if (!(Test-Path $addonsDir)) {
        throw "WoW AddOns folder not found:`n$addonsDir`nEdit wow_path in config.json."
    }

    # Read installed version from TOC, if any.
    $installedVersion = "not installed"
    $toc = Join-Path $targetDir "$addonName.toc"
    if (Test-Path $toc) {
        $line = Get-Content $toc | Where-Object { $_ -match "^## Version:" } | Select-Object -First 1
        if ($line) { $installedVersion = ($line -replace "^## Version:\s*","").Trim() }
    }
    Write-Host "Installed version: $installedVersion"

    $headers = @{
        "User-Agent" = "GAPer-Updater"
        "Accept" = "application/vnd.github+json"
    }
    $releaseUrl = "https://api.github.com/repos/$repo/releases/latest"

    Write-Host "Checking GitHub..."
    try {
        $release = Invoke-RestMethod -Uri $releaseUrl -Headers $headers
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            throw "Repository or a published GitHub Release was not found.`nCreate a PUBLIC repo named GAPer-Forever and publish a release containing $assetName."
        }
        throw
    }

    $latest = [string]$release.tag_name
    Write-Host "Latest release:    $latest"

    $asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if (!$asset) {
        throw "Release asset '$assetName' was not found in release $latest."
    }

    # Version compare is intentionally simple: if release tag contains installed version, skip.
    $installedNormalized = $installedVersion.TrimStart("v")
    $latestNormalized = $latest.TrimStart("v")
    if ($latestNormalized -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid release version.' }
    if ($installedVersion -ne 'not installed' -and [version]$installedNormalized -ge [version]$latestNormalized) {
        Write-Host ""
        Write-Host "GAPer is already up to date." -ForegroundColor Green
        if ($LaunchBattleNet -or $cfg.launch_wow_after_update) {
            $launcher = Join-Path ${env:ProgramFiles(x86)} "Battle.net\Battle.net Launcher.exe"
            if (Test-Path $launcher) { Start-Process $launcher -WindowStyle Hidden }
        }
        Pause-End
        exit 0
    }

    Write-Host ""
    Write-Host "Update available: $installedVersion -> $latest" -ForegroundColor Cyan

    $tempBase = Join-Path $env:TEMP ("GAPerUpdate_" + [guid]::NewGuid().ToString("N"))
    $zipPath = Join-Path $tempBase $assetName
    $extractDir = Join-Path $tempBase "extract"
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    if (Get-Process -Name Wow,WowClassic,WowClassicB,WowB -ErrorAction SilentlyContinue) { throw 'Close WoW before updating.' }
    if ((Test-Path -LiteralPath $targetDir) -and ((Get-Item -LiteralPath $targetDir).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Addon folder must not be a junction or symlink.' }
    Write-Host "Downloading..."
    $expectedPrefix = "https://github.com/$repo/releases/download/"
    if (!([string]$asset.browser_download_url).StartsWith($expectedPrefix)) { throw 'Unexpected download URL.' }
    Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -Headers $headers -OutFile $zipPath
    $checksumAsset = @($release.assets | Where-Object name -eq 'SHA256SUMS.txt')
    if ($checksumAsset.Count -ne 1) { throw 'Missing checksum asset.' }
    if (!([string]$checksumAsset[0].browser_download_url).StartsWith($expectedPrefix)) { throw 'Unexpected checksum URL.' }
    $checksumPath = Join-Path $tempBase 'SHA256SUMS.txt'
    Invoke-WebRequest -UseBasicParsing -Uri $checksumAsset[0].browser_download_url -Headers $headers -OutFile $checksumPath
    $sum = @(Get-Content -LiteralPath $checksumPath | Where-Object { $_ -match '^[a-fA-F0-9]{64}  GAPerGuide\.zip$' })
    if ($sum.Count -ne 1) { throw 'Invalid checksum file.' }
    if ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -ne ($sum[0] -split ' ')[0]) { throw 'SHA-256 verification failed.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $archive.Entries) {
            $entryName = $entry.FullName.Replace('\','/')
            if (!$entryName.StartsWith('GAPerGuide/') -or $entryName -match '(^|/)\.\.(/|$)|:') { throw 'Unsafe archive path.' }
        }
    } finally { $archive.Dispose() }

    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    # Accept either GAPerGuide/ at archive root or files directly at root.
    $sourceDir = Join-Path $extractDir $addonName
    if (!(Test-Path $sourceDir)) {
        $candidateToc = Get-ChildItem -Path $extractDir -Filter "$addonName.toc" -Recurse | Select-Object -First 1
        if ($candidateToc) {
            $sourceDir = Split-Path -Parent $candidateToc.FullName
        }
    }
    if (!(Test-Path (Join-Path $sourceDir "$addonName.toc"))) {
        throw "Downloaded archive does not contain $addonName\$addonName.toc"
    }

    $sourceToc = Get-Content -LiteralPath (Join-Path $sourceDir 'GAPerGuide.toc') -Raw
    $versionMatch = [regex]::Match($sourceToc, '(?m)^## Version:\s*(\d+\.\d+\.\d+)\s*$')
    if (!$versionMatch.Success -or [version]$versionMatch.Groups[1].Value -ne [version]$latestNormalized) { throw 'Archive version differs from release.' }
    if (!(Test-Path -LiteralPath (Join-Path $sourceDir 'GAPer.lua'))) { throw 'Missing addon code.' }
    $backupRoot = Join-Path $wowPath 'GAPerBackups'
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    $backupDir = Join-Path $backupRoot ('GAPerGuide_' + [guid]::NewGuid().ToString('N'))
    $stage = Join-Path $addonsDir ('GAPerStage_' + [guid]::NewGuid().ToString('N'))
    Copy-Item -LiteralPath $sourceDir -Destination $stage -Recurse
    $hadTarget = Test-Path -LiteralPath $targetDir
    if ($hadTarget) { Move-Item -LiteralPath $targetDir -Destination $backupDir }
    try { Move-Item -LiteralPath $stage -Destination $targetDir }
    catch {
        if ($hadTarget -and !(Test-Path -LiteralPath $targetDir)) { Move-Item -LiteralPath $backupDir -Destination $targetDir }
        throw
    }
    Write-Host "Backup: $backupDir"
    $newVersion = $latest
    $newToc = Join-Path $targetDir "$addonName.toc"
    if (Test-Path $newToc) {
        $line = Get-Content $newToc | Where-Object { $_ -match "^## Version:" } | Select-Object -First 1
        if ($line) { $newVersion = ($line -replace "^## Version:\s*","").Trim() }
    }

    $resolvedTemp = [IO.Path]::GetFullPath($tempBase)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolvedTemp.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolvedTemp -Leaf) -notmatch '^GAPerUpdate_[a-f0-9]{32}$') { throw 'Unexpected temporary path.' }
    Remove-Item -LiteralPath $resolvedTemp -Recurse -Force

    Write-Host ""
    Write-Host "SUCCESS: GAPer updated to $newVersion" -ForegroundColor Green
    Write-Host "Your WoW SavedVariables were not touched." -ForegroundColor Green

    if ($LaunchBattleNet -or $cfg.launch_wow_after_update) {
        # Battle.net normally owns launching WoW. Try common launcher path only if present.
        $battleNet = "${env:ProgramFiles(x86)}\Battle.net\Battle.net Launcher.exe"
        if (Test-Path $battleNet) {
            Write-Host "Launching Battle.net..."
            Start-Process $battleNet -WindowStyle Hidden
        }
    }

    Pause-End
}
catch {
    Write-Host ""
    Write-Host "UPDATE ERROR" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Pause-End
    exit 1
}
