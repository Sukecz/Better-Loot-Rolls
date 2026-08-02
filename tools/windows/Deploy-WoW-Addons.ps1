[CmdletBinding()]
param(
    [string]$Server = "minipc",
    [string]$ProjectsRoot = "/home/msminipc/projects",
    [string]$WowAddOnsPath = "C:\Games\World of Warcraft\_classic_era_\Interface\AddOns",
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wow-addons-deploy-" + [guid]::NewGuid().ToString("N"))
$exitCode = 0
$versions = @{}

$addons = @(
    [pscustomobject]@{
        DisplayName = "Simple Scrolling Loot"
        ProjectDirectory = "ssl"
        AddonName = "SimpleScrollingLoot"
        PrimaryToc = "SimpleScrollingLoot.toc"
        RequiredFiles = @(
            "SimpleScrollingLoot.toc",
            "SimpleScrollingLoot_TBC.toc",
            "Core.lua",
            "Options.lua",
            "Locales\enUS.lua",
            "assets\ssl.png"
        )
    },
    [pscustomobject]@{
        DisplayName = "Better Loot Rolls"
        ProjectDirectory = "blr"
        AddonName = "BetterLootRolls"
        PrimaryToc = "BetterLootRolls.toc"
        RequiredFiles = @(
            "BetterLootRolls.toc",
            "BetterLootRolls_TBC.toc",
            "Core.lua",
            "Options.lua",
            "Locales\enUS.lua",
            "assets\logo.png"
        )
    },
    [pscustomobject]@{
        DisplayName = "Simple Arsenal Swap"
        ProjectDirectory = "sas"
        AddonName = "SimpleArsenalSwap"
        PrimaryToc = "SimpleArsenalSwap.toc"
        RequiredFiles = @(
            "SimpleArsenalSwap.toc",
            "SimpleArsenalSwap_TBC.toc",
            "Core.lua",
            "Swap.lua",
            "Options.lua",
            "Locales\enUS.lua",
            "assets\logo.png"
        )
    }
)

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

function Get-RemoteProjectPath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Addon
    )

    return "$ProjectsRoot/$($Addon.ProjectDirectory)"
}

function Get-StagedAddonPath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Addon
    )

    return Join-Path $stageRoot $Addon.AddonName
}

function Test-RemoteAddon {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Addon,

        [Parameter(Mandatory = $true)]
        [string]$SshExecutable
    )

    $remoteProject = Get-RemoteProjectPath -Addon $Addon
    Write-Host "  Testing $($Addon.DisplayName)..." -ForegroundColor DarkCyan
    Invoke-NativeCommand `
        -Executable $SshExecutable `
        -Arguments @($Server, "cd '$remoteProject' && bash tests/run.sh") `
        -FailureMessage "$($Addon.DisplayName) tests failed. Nothing was copied."
}

function Stage-RemoteAddon {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Addon,

        [Parameter(Mandatory = $true)]
        [string]$ScpExecutable
    )

    $remoteProject = Get-RemoteProjectPath -Addon $Addon
    $stageAddon = Get-StagedAddonPath -Addon $Addon
    New-Item -ItemType Directory -Path $stageAddon -Force | Out-Null

    Write-Host "  Downloading $($Addon.DisplayName)..." -ForegroundColor DarkCyan
    Invoke-NativeCommand `
        -Executable $ScpExecutable `
        -Arguments @(
            "$Server`:$remoteProject/*.lua",
            "$Server`:$remoteProject/*.toc",
            $stageAddon
        ) `
        -FailureMessage "Could not download $($Addon.DisplayName) Lua or TOC files."

    Invoke-NativeCommand `
        -Executable $ScpExecutable `
        -Arguments @(
            "-r",
            "$Server`:$remoteProject/Locales",
            "$Server`:$remoteProject/assets",
            $stageAddon
        ) `
        -FailureMessage "Could not download $($Addon.DisplayName) locale or asset files."

    foreach ($relativePath in $Addon.RequiredFiles) {
        $requiredFile = Join-Path $stageAddon $relativePath
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            throw "$($Addon.DisplayName) download is incomplete. Missing: $requiredFile"
        }
    }

    $tocPath = Join-Path $stageAddon $Addon.PrimaryToc
    $tocContent = Get-Content -LiteralPath $tocPath -Raw
    $versionMatch = [regex]::Match($tocContent, '(?m)^## Version:[ \t]*(.+?)[ \t]*$')
    if (-not $versionMatch.Success) {
        throw "$($Addon.DisplayName) TOC does not contain a readable version."
    }
    $versions[$Addon.AddonName] = $versionMatch.Groups[1].Value.Trim()
}

function Sync-StagedAddon {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Addon,

        [Parameter(Mandatory = $true)]
        [string]$RobocopyExecutable
    )

    $stageAddon = Get-StagedAddonPath -Addon $Addon
    $destination = Join-Path $WowAddOnsPath $Addon.AddonName
    New-Item -ItemType Directory -Path $destination -Force | Out-Null

    Write-Host "  Updating $($Addon.DisplayName) $($versions[$Addon.AddonName])..." -ForegroundColor DarkCyan
    & $RobocopyExecutable $stageAddon $destination /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -ge 8) {
        throw "Robocopy failed while updating $destination (exit code $robocopyExitCode)"
    }
}

try {
    $ssh = (Get-Command "ssh.exe" -ErrorAction Stop).Source
    $scp = (Get-Command "scp.exe" -ErrorAction Stop).Source
    $robocopy = (Get-Command "robocopy.exe" -ErrorAction Stop).Source

    if (-not (Test-Path -LiteralPath $WowAddOnsPath -PathType Container)) {
        throw "WoW AddOns folder does not exist: $WowAddOnsPath"
    }

    Write-Host "1/3 Testing all addons on MINIPC..." -ForegroundColor Cyan
    foreach ($addon in $addons) {
        Test-RemoteAddon -Addon $addon -SshExecutable $ssh
    }

    Write-Host "2/3 Downloading and validating all addons..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    foreach ($addon in $addons) {
        Stage-RemoteAddon -Addon $addon -ScpExecutable $scp
    }

    Write-Host "3/3 Synchronizing the WoW AddOns folder..." -ForegroundColor Cyan
    foreach ($addon in $addons) {
        Sync-StagedAddon -Addon $addon -RobocopyExecutable $robocopy
    }

    Write-Host ""
    Write-Host "All three addons are up to date:" -ForegroundColor Green
    foreach ($addon in $addons) {
        Write-Host "  $($addon.DisplayName) $($versions[$addon.AddonName])" -ForegroundColor Green
    }
    Write-Host "In WoW, enter /reload to load the current files." -ForegroundColor Green
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
