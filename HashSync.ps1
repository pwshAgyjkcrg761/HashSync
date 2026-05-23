# ==============================================================================
# SCRIPT: HashSync.ps1
# VERSION: 2026.05.23_10.20.15
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
$scriptVersion = "2026.05.23_10.20.15"

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

# Save updated operational states immediately back to configuration store
$Config | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $ConfigFile -Encoding utf8

# If the user is only setting the NAS path, exit after saving
if ($PSBoundParameters.ContainsKey('SetNASRootPath') -and -not $PSBoundParameters.ContainsKey('BackUpPath')) {
    Write-Host "Configuration Updated." -ForegroundColor DarkGreen
    Write-Host "NAS Root set to: $($Config['SetNASRootPath'])" -ForegroundColor Gray
    exit
}

# Ensure requiDarkRed deployment configurations exist before continuing
if ([string]::IsNullOrWhiteSpace($Config['SetNASRootPath'])) {
    Write-Host "ERROR: Operational failure. NAS source root path has not been declaDarkRed." -ForegroundColor DarkRed
    Write-Host "Syntax requiDarkRed: .\HashSync.ps1 -SetNASRootPath '\\NAS\Root' -BackUpPath 'F:\Target'" -ForegroundColor DarkYellow
    Read-Host "Press Enter to exit"
    exit
}

$NasRoot = $Config['SetNASRootPath']

# 2. Establish Execution and Destination Targets (Supports Multiple Folders)
$TargetPaths = @()
if ($PSBoundParameters.ContainsKey('BackUpPath') -and $BackUpPath.Count -gt 0) {
    foreach ($Path in $BackUpPath) { $TargetPaths += [System.IO.Path]::GetFullPath($Path) }
} elseif ($args.Count -gt 0) {
    foreach ($Path in $args) { $TargetPaths += [System.IO.Path]::GetFullPath($Path) }
} else {
    $TargetPaths += [System.IO.Path]::GetFullPath($PWD.Path)
}


# 3. ANALYSIS PHASE (Pre-check all folders)
$Results = @()
$NasFolderName = Split-Path -Path $NasRoot -Leaf

foreach ($DestPath in $TargetPaths) {
    $Entry = [PSCustomObject]@{
        Destination = $DestPath
        Source      = ""
        Match       = "NO"
        Error       = ""
        Diff        = $null
    }

    # Path Mapping
    $RootIndex = $DestPath.IndexOf($NasFolderName, [System.StringComparison]::OrdinalIgnoreCase)
    if ($RootIndex -ge 0) {
        $RelativePath = $DestPath.Substring($RootIndex + $NasFolderName.Length).TrimStart('\').TrimStart('/')
        $Entry.Source = if ([string]::IsNullOrWhiteSpace($RelativePath)) { $NasRoot } else { Join-Path -Path $NasRoot -ChildPath $RelativePath }
    } else { $Entry.Source = $NasRoot }

    # Validation
    if ($DestPath.StartsWith($NasRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $Entry.Error = "Target inside Source"
    } elseif (-not (Test-Path -LiteralPath $Entry.Source)) {
        $Entry.Error = "NAS Path Missing"
    } else {
        # Structural Check
        $DestFolders = @(Get-ChildItem -LiteralPath $DestPath -Recurse -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($DestPath.Length) } | Sort-Object)
        $SourceFolders = @(Get-ChildItem -LiteralPath $Entry.Source -Recurse -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($Entry.Source.Length) } | Sort-Object)
        
        $Diff = $null
        if ($SourceFolders.Count -gt 0 -or $DestFolders.Count -gt 0) {
            $Diff = Compare-Object -ReferenceObject $SourceFolders -DifferenceObject $DestFolders
        }
        
        if ($null -eq $Diff) { 
            $Entry.Match = "YES" 
        } else { 
            $Entry.Diff = $Diff 
        }
    }
    $Results += $Entry
}

# --- STARTUP DISPLAY ---
Clear-Host
Write-Host "==================================================" -ForegroundColor DarkYellow
Write-Host "        HashSync.ps1 v$scriptVersion" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor DarkYellow
Write-Host "NAS Root: " -NoNewline; Write-Host $NasRoot -ForegroundColor DarkMagenta
Write-Host "--------------------------------------------------" -ForegroundColor DarkYellow

foreach ($R in $Results) {
    $Color = if ($R.Match -eq "YES") { "DarkGreen" } else { "DarkRed" }
    Write-Host "Hash Destination(s):" -ForegroundColor Gray
    Write-Host "" -NoNewLine; Write-Host "  -> $($R.Destination)" -ForegroundColor DarkCyan
    # Write-Host "Hash Destination: $($R.Destination)" -ForegroundColor DarkBlue
    Write-Host "Match:  " -NoNewline; Write-Host $R.Match -ForegroundColor $Color
    if ($R.Error) { Write-Host "Error:  $($R.Error)" -ForegroundColor DarkRed }
    Write-Host "--------------------------------------------------" -ForegroundColor DarkYellow
}

# Detailed Errors for Mismatches
$Mismatches = $Results | Where-Object { $_.Match -eq "NO" -and -not $_.Error }
if ($Mismatches) {
    Write-Host "`nSTRUCTURE MISMATCH DETAILS:" -ForegroundColor DarkRed
    foreach ($M in $Mismatches) {
        Write-Host " Folder: $($M.Destination)" -ForegroundColor DarkYellow
        $M.Diff | ForEach-Object {
            $Side = if ($_.SideIndicator -eq "<=") { "Missing on Backup" } else { "Extra on Backup" }
            Write-Host "  - $($Side): $($_.InputObject)" -ForegroundColor DarkGray
        }
    }
    Write-Host "--------------------------------------------------`n" -ForegroundColor DarkYellow
}



# 7. USER CONFIRMATION
$ValidTargets = $Results | Where-Object { $_.Match -eq "YES" }

if ($ValidTargets.Count -eq 0) {
    Write-Host "No folders are eligible for sync. Check mismatches above." -ForegroundColor DarkRed
    Read-Host "Press Enter to exit"
    exit
}

$Message = "HashSync $($ValidTargets.Count) matching folder(s)?"
$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Starts the copy."
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Aborts."
$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

if ($host.ui.PromptForChoice("", $Message, $Options, 1) -ne 0) {
    Write-Host "Operation cancelled." -ForegroundColor DarkYellow
    exit
}

# 8. EXECUTION PHASE (Copy only matched folders)
foreach ($Target in $ValidTargets) {
    Write-Host "`nHashSyncing: $($Target.Destination)" -ForegroundColor DarkCyan
    $HashFiles = Get-ChildItem -LiteralPath $Target.Source -Filter "*.hash" -Recurse -File

    if ($HashFiles.Count -eq 0) {
        Write-Host " No .hash files found on NAS." -ForegroundColor DarkYellow
    } else {
        foreach ($File in $HashFiles) {
            $FileRelPath = $File.FullName.Substring($Target.Source.Length)
            $TargetPath = Join-Path -Path $Target.Destination -ChildPath $FileRelPath
            
            $TargetDir = Split-Path -Path $TargetPath -Parent
            if (-not (Test-Path -LiteralPath $TargetDir)) {
                New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            }

            try {
                Copy-Item -LiteralPath $File.FullName -Destination $TargetPath -Force -ErrorAction Stop
                Write-Host " Updated: $FileRelPath" -ForegroundColor Gray
            }
            catch { Write-Warning " Failed to copy: $($File.Name)" }
        }
    }
}

Write-Host "`nAll tasks finished." -ForegroundColor DarkGreen
Read-Host "Press Enter to close"
exit