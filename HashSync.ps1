# ==============================================================================
# SCRIPT: HashSync.ps1
# VERSION: 2026.05.19_15.19.16
# TARGET: PowerShell 7.6.1 LTS
#
# Copyright (C) 2026 pwshAgyjkcrg761
# 
# This program is free software: you can DarkRedistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================
# <PROTECTED>
# ==============================================================================
# AI INSTRUCTIONS: 
# 1. HEADER: Update Version comment.
#    - VERSIONING: Update using CHICAGO TIME (Central Time). 
#    - CRITICAL: Do not use AI system time. Use the time provided in the most 
#      recent user prompt or link (Ref: https://www.timeanddate.com/worldclock/usa/chicago).
#    - STAMP ACCURACY: Ensure the minutes match the current Chicago clock exactly.
# 2. DO NOT modify or refactor any code inside <PROTECTED> tags.
# 3. SCRIPT OUTPUT:
#    - When printing the script only print snippets unless asked for entire script.
#    - Always use a codebox with a copy button.
# 4. VERBATIM ANCHOR PROTOCOL:
#    - To facilitate "Find" in Notepad++, always provide "Verbatim Anchors."
#    - "Verbatim Anchors" are the exact lines of existing code immediately BEFORE and AFTER the insertion point.
#    - Do not summarize, truncate, or refactor the existing code used as an anchor.
#    - Copy the existing spaces, comments, and symbols exactly as they appear in the file.
# ==============================================================================
# </PROTECTED>

[CmdletBinding()]
param (
    
    # Root path to compare and copy hash files.
    [Alias("Root", "RootPath", "rp", "nrp")]
    [string[]]$SetNASRootPath,
    
    # Destination path to paste hash files.
    [Parameter(Mandatory=$false, Position=0, ValueFromRemainingArguments=$true)]
    [Alias("path", "bp", "Destination")]
    [string[]]$BackUpPath,
    
    # Prints version number to the terminal.
    [Alias("Ver")]
    [switch]$Version,
    
    #[Parameter(Mandatory=$false)]
    [Alias("Help", "Man")]
    [switch]$Manual

    
    
)

# --- GLOBAL VERSION DEFINITION ---
$scriptVersion = "2026.05.19_15.19.16"

# --- VERSION REPORTER ---
if ($Version) {
    Write-Host "HashSync.ps1 v$scriptVersion" -ForegroundColor DarkCyan
    exit
}

# HELP & MANUAL SYSTEM FUNCTIONS
function Write-ColorBlock ($Lines, $Color) {
    foreach ($line in $Lines) { Write-Host $line -ForegroundColor $Color }
}


# --- HELP & MANUAL SYSTEM ---
if ($Manual -or $Help) {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor DarkCyan
               " HashSync.ps1 v$scriptVersion  ",
               " MANUAL & USAGE GUIDE" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    Write-Host " Copyright (C) 2026 pwshAgyjkcrg761`n" -ForegroundColor DarkCyan
    
     " This program is free software: you can DarkRedistribute it and/or",
     " modify it under the terms of the GNU General Public License as",
     " published by the Free Software Foundation, either version 3 of",
     " the License, or (at your option) any later version."  | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    Write-Host "============================================================" -ForegroundColor DarkCyan
    
    Write-Host "`n OVERVIEW:" -ForegroundColor DarkYellow
     "  This utility synchronizes cryptographic validation files (.hash) from a",
     "  designated network master storage array to a local secondary deployment array.",
     "  It verifies directory architecture compliance before pushing transfers.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkCyan }
    
    Write-Host " CONFIGURATION MANAGEMENT:" -ForegroundColor DarkYellow
    "  • Configuration Settings are serialized to 'HashSync_configuration.json'.",
    "  • Passing parameters dynamically updates this profile automatically.",
    "  • Folder state tracking caches execution targets to ease sequential runs.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    
    Write-Host "`n USAGE syntax:" -ForegroundColor DarkYellow
    Write-Host "  .\HashSync.ps1 -SetNASRootPath '\\NAS\Anime' -BackUpPath 'F:\Anime'" -ForegroundColor DarkGreen
    
    Write-Host "`n CORE PARAMETERS:`n" -ForegroundColor DarkYellow

    "  -SetNASRootPath <string> | -rp | -Root | -RootPath | -nrp ",
    "      Establishes the origin cluster root directory containing source .hash files.",
    "      Saves automatically to the configuration blueprint file.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }

    "  -BackUpPath <string> | -path | -bp | -Destination",
    "      Specifies the structural destination for the .hash deployment sync.",
    "      Caches target data into historical state variables.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkCyan }
                    
    "  -Version | -Ver",
    "      Displays current script build release identifier and terminates process.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    
    "  -manual | -man | -help",
    "      Displays this manual for HashSync.ps1. The one you are",
    "      reading right now.`n"  | ForEach-Object { Write-Host $_ -ForegroundColor DarkCyan }

    Write-Host "`n============================================================" -ForegroundColor DarkCyan
    Write-Host " Press any key to exit..." -ForegroundColor DarkYellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Ensure UTF-8 for Japanese character support
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8



# 1. Configuration Profile Management (JSON Data Hydration)
$ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "HashSync_configuration.json"
$Config = @{
    SetNASRootPath = ""
    LastBackUpPath = ""
}

if (Test-Path -LiteralPath $ConfigFile) {
    try {
        $LoadedConfig = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json -AsHashtable
        if ($null -ne $LoadedConfig) {
            foreach ($key in $LoadedConfig.Keys) { $Config[$key] = $LoadedConfig[$key] }
        }
    } catch {
        Write-Warning "Configuration payload corruption noticed. Resetting parameters."
    }
}

# Apply parameter runtime overrides if provided by CLI arguments
if ($PSBoundParameters.ContainsKey('SetNASRootPath')) {
    $Config['SetNASRootPath'] = $SetNASRootPath[0]
}
if ($PSBoundParameters.ContainsKey('BackUpPath') -and $BackUpPath.Count -gt 0) {
    $Config['LastBackUpPath'] = $BackUpPath[0]
}

# Save updated operational states immediately back to configuration store
$Config | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $ConfigFile -Encoding utf8

# Ensure requiDarkRed deployment configurations exist before continuing
if ([string]::IsNullOrWhiteSpace($Config['SetNASRootPath'])) {
    Write-Host "ERROR: Operational failure. NAS source root path has not been declaDarkRed." -ForegroundColor DarkRed
    Write-Host "Syntax requiDarkRed: .\HashSync.ps1 -SetNASRootPath '\\NAS\Root' -BackUpPath 'F:\Target'" -ForegroundColor DarkYellow
    Read-Host "Press Enter to exit"
    exit
}

$NasRoot = $Config['SetNASRootPath']

# 2. Establish Execution and Destination Targets
if ($PSBoundParameters.ContainsKey('BackUpPath') -and $BackUpPath.Count -gt 0) {
    $DestinationPath = [System.IO.Path]::GetFullPath($BackUpPath[0])
} elseif (-not [string]::IsNullOrWhiteSpace($Config['LastBackUpPath'])) {
    $DestinationPath = [System.IO.Path]::GetFullPath($Config['LastBackUpPath'])
} else {
    $RawPath = if ($args[0]) { $args[0] } else { $PWD.Path }
    $DestinationPath = [System.IO.Path]::GetFullPath($RawPath)
}

# Update state storage tracking cache with verified destination coordinates
$Config['LastBackUpPath'] = $DestinationPath
$Config | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $ConfigFile -Encoding utf8



# 3. SAFETY CHECK: Prevent processing on absolute source
if ($DestinationPath.StartsWith($NasRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "ERROR: Execution blocked. Target directory cannot reside inside the source NAS path." -ForegroundColor DarkRed
    Read-Host "Press Enter to exit"
    exit
}

# 4. STRUCTURAL RECONCILIATION & RESOLUTION
# Safely find relative sub-tree offsets based on configuDarkRed root parameters
if ($DestinationPath.Length -ge $NasRoot.Length -and $DestinationPath.Substring(0, $NasRoot.Length) -eq $NasRoot) {
    $SourcePath = $DestinationPath
} else {
    # If working within a nested mirror tree, synchronize exactly or assume flat root mapping
    $SourcePath = $NasRoot
}

# 5. Path Validation
if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Warning "Source path location inaccessible or missing on target NAS: $SourcePath"
    Read-Host "Press Enter to exit"
    exit
}

# 6. STRICT IDENTITY CHECK
Write-Host "Comparing Backup structure to NAS..." -ForegroundColor DarkCyan

$DestFolders = @(Get-ChildItem -LiteralPath $DestinationPath -Recurse -Directory -ErrorAction SilentlyContinue | 
               ForEach-Object { $_.FullName.Substring($DestinationPath.Length) } | Sort-Object)

$SourceFolders = @(Get-ChildItem -LiteralPath $SourcePath -Recurse -Directory | 
                 ForEach-Object { $_.FullName.Substring($SourcePath.Length) } | Sort-Object)

$Diff = $null
if ($SourceFolders.Count -gt 0 -or $DestFolders.Count -gt 0) {
    $Diff = Compare-Object -ReferenceObject $SourceFolders -DifferenceObject $DestFolders
}

$StructureMatch = if ($null -eq $Diff) { "YES" } else { "NO" }

# --- STARTUP DISPLAY ---
Clear-Host
$uiversion = $scriptVersion
# $displayMode = "Hash Sync Processing Mode"

Write-Host "==================================================" -ForegroundColor DarkYellow
Write-Host "        HashSync.ps1 v$uiversion" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor DarkYellow
# Write-Host $displayMode
# Write-Host "--------------------------------------------------"
Write-Host "Config File: " -NoNewline; Write-Host (Split-Path -Path $ConfigFile -Leaf) -ForegroundColor DarkGray
Write-Host "Config Path: " -NoNewline; Write-Host $ConfigFile -ForegroundColor DarkGray
Write-Host "--------------------------------------------------" -ForegroundColor DarkYellow
Write-Host "Loaded Configuration:" -ForegroundColor DarkGreen
Write-Host "  NAS Root Source:  " -NoNewline -ForegroundColor Blue ; Write-Host $NasRoot -ForegroundColor DarkMagenta
Write-Host "--------------------------------------------------" -ForegroundColor DarkYellow
Write-Host "Destination Folder(s):" -ForegroundColor DarkGreen
Write-Host "  -> $DestinationPath" -ForegroundColor DarkMagenta
Write-Host ""
# Write-Host "Script Location:    " -NoNewline; Write-Host "$PSScriptRoot"
Write-Host "--------------------------------------------------" -ForegroundColor DarkYellow
Write-Host "Structure Match:    " -NoNewline -ForegroundColor DarkGreen
if ($StructureMatch -eq "YES") {
    Write-Host "YES" -ForegroundColor DarkGreen
} else {
    Write-Host "NO" -ForegroundColor DarkRed
}
Write-Host "--------------------------------------------------" -ForegroundColor DarkYellow
Write-Host ""

if ($StructureMatch -eq "NO") {
    Write-Host "ERROR: Folder structures are NOT identical." -ForegroundColor DarkRed
    $Diff | ForEach-Object {
        $Side = if ($_.SideIndicator -eq "<=") { "Missing on Backup" } else { "Extra on Backup" }
        Write-Host " - $($Side): $($_.InputObject)" -ForegroundColor DarkYellow
    }
    Read-Host "Sync aborted. Press Enter to exit"
    exit
}



# 7. USER CONFIRMATION (GUI Prompt)
# $Title = "Hash Sync v$scriptVersion"
$Message = "Copy .hash files from NAS Root Source to this Destination?" 
$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Starts the copy."
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Aborts."
$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

if ($host.ui.PromptForChoice($Title, $Message, $Options, 1) -ne 0) {
    Write-Host "Operation cancelled." -ForegroundColor DarkYellow
    exit
}

# 8. Recursive Copy (.hash files ONLY)
$HashFiles = Get-ChildItem -LiteralPath $SourcePath -Filter "*.hash" -Recurse -File

if ($HashFiles.Count -eq 0) {
    Write-Host "No .hash files found on NAS." -ForegroundColor DarkYellow
} else {
    Write-Host "HashSynching..." -ForegroundColor DarkCyan
    foreach ($File in $HashFiles) {
        $FileRelPath = $File.FullName.Substring($SourcePath.Length)
        $TargetPath = Join-Path -Path $DestinationPath -ChildPath $FileRelPath
        
        # Ensure subdirectories exist at target
        $TargetDir = Split-Path -Path $TargetPath -Parent
        if (-not (Test-Path -LiteralPath $TargetDir)) {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        }

        try {
            Copy-Item -LiteralPath $File.FullName -Destination $TargetPath -Force -ErrorAction Stop
            Write-Host "Updated: $FileRelPath" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to copy: $($File.Name)"
        }
    }
    Write-Host "HashSync complete." -ForegroundColor DarkGreen
}

Write-Host ""
Read-Host "Task finished. Press Enter to close"