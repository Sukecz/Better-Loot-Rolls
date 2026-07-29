[CmdletBinding()]
param(
    [string]$Server = "minipc",
    [string]$RemoteProject = "/home/msminipc/projects/blr",
    [string]$WowAddOnsPath = "C:\Games\World of Warcraft\_classic_era_\Interface\AddOns",
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
$addonName = "BetterLootRolls"
$destination = Join-Path $WowAddOnsPath $addonName
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("blr-deploy-" + [guid]::NewGuid().ToString("N"))
$stageAddon = Join-Path $stageRoot $addonName
$exitCode = 0

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)"
    }
}

try {
    $ssh = (Get-Command "ssh.exe" -ErrorAction Stop).Source
    $scp = (Get-Command "scp.exe" -ErrorAction Stop).Source
    $robocopy = (Get-Command "robocopy.exe" -ErrorAction Stop).Source

    if (-not (Test-Path -LiteralPath $WowAddOnsPath -PathType Container)) {
        throw "WoW AddOns folder does not exist: $WowAddOnsPath"
    }

    New-Item -ItemType Directory -Path $stageAddon -Force | Out-Null

    Write-Host "1/3 Testing the current addon on MINIPC..." -ForegroundColor Cyan
    Invoke-NativeCommand `
        -Executable $ssh `
        -Arguments @($Server, "cd '$RemoteProject' && bash tests/run.sh") `
        -FailureMessage "Server-side addon tests failed. Nothing was copied."

    Write-Host "2/3 Downloading addon files over SSH..." -ForegroundColor Cyan
    Invoke-NativeCommand `
        -Executable $scp `
        -Arguments @(
            "$Server`:$RemoteProject/*.lua",
            "$Server`:$RemoteProject/*.toc",
            $stageAddon
        ) `
        -FailureMessage "Could not download the addon Lua or TOC files."

    Invoke-NativeCommand `
        -Executable $scp `
        -Arguments @(
            "-r",
            "$Server`:$RemoteProject/Locales",
            "$Server`:$RemoteProject/assets",
            $stageAddon
        ) `
        -FailureMessage "Could not download the addon locale or asset files."

    $requiredFiles = @(
        (Join-Path $stageAddon "BetterLootRolls.toc"),
        (Join-Path $stageAddon "BetterLootRolls_TBC.toc"),
        (Join-Path $stageAddon "Core.lua"),
        (Join-Path $stageAddon "Locales\enUS.lua"),
        (Join-Path $stageAddon "assets\logo.png")
    )
    foreach ($requiredFile in $requiredFiles) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            throw "Downloaded addon is incomplete. Missing: $requiredFile"
        }
    }

    Write-Host "3/3 Synchronizing the WoW AddOns folder..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    & $robocopy $stageAddon $destination /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -ge 8) {
        throw "Robocopy failed while updating $destination (exit code $robocopyExitCode)"
    }

    Write-Host ""
    Write-Host "Better Loot Rolls was updated successfully." -ForegroundColor Green
    Write-Host "In WoW, enter /reload to load the new files." -ForegroundColor Green
}
catch {
    $exitCode = 1
    Write-Host ""
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}

if (-not $NoPause) {
    Write-Host ""
    Read-Host "Press Enter to close"
}

exit $exitCode
