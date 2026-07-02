# HashSync.ps1

**A high-fidelity media management and cryptographic validation automation script for PowerShell 7.6.x LTS. It enforces strict target directory architecture compliance before safely synchronizing .hash files from a network master array to a secondary backup.**

---

## Overview
`HashSync.ps1` is a robust automation utility designed to synchronize cryptographic validation files (`.hash`) from a designated network master storage array to a local secondary deployment array. Built for data integrity and archival consistency, the script acts as a safety barrier by running a strict structural reconciliation check across your library before any file operations are executed. This prevents metadata misalignment and ensures that your secondary backup mirrors the master directory architecture flawlessly.

## Technical Logic
The script operates with a dual-stage execution model—combining configuration profile automation with an identity validation engine—to achieve seamless operations. It serializes variables to a dedicated JSON backend, tracking your source cluster configurations and caching local targets dynamically to make sequential runs effortless. Before executing a copy sequence, it verifies target directory architecture compliance. If any structural discrepancies or mismatches are discovered between the master array and the deployment directory, execution halts safely with a detailed reconciliation output.

## Usage Examples
```powershell
# Standard Sync targeting a specific source and backup destination
.\HashSync.ps1 -SetNASRootPath '\\NAS\Anime' -BackUpPath 'F:\Anime'

# Execution utilizing parameter shorthand and folder aliases
.\HashSync.ps1 -rp '\\NAS\Anime' -bp 'F:\Anime'

# Display build release version and terminate execution immediately
.\HashSync.ps1 -Version

# Launch the interactive text-based terminal help manual
.\HashSync.ps1 -Manual
```

## Parameter Reference

### Core Parameters & Aliases
| Parameter | Aliases | Description |
| :--- | :--- | :--- |
| **`-SetNASRootPath <string>`** | `-rp`, `-Root`, `-RootPath`, `-nrp` | Establishes the origin cluster root directory containing source `.hash` validation files. Saves parameters automatically to the local configuration state. |
| **`-BackUpPath <string>`** | `-path`, `-bp`, `-Destination` | Specifies the absolute target destination for the `.hash` deployment sync. Automatically caches coordinates into historical state variables. |
| **`-Version`** | `-Ver` | Displays the current script build release identifier to the terminal host interface and exits immediately. |
| **`-Manual`** | `-man`, `-help` | Clears the host screen and displays the internal usage guide, parameter dictionary, and syntax manual. |

---

## Configuration Management
* **Configuration Profile**: System settings are automatically serialized to `HashSync_configuration.json` inside the script's root executing folder.
* **Parameter Hydration**: Passing active parameters dynamically updates your cached profile blueprint automatically.
* **State Caching**: The application automatically tracks and handles historical execution coordinates to optimize sequential operations across runtime tasks.

## Dependencies
* **PowerShell 7.6.x LTS**: Built and optimized for modern LTS shell features.
* **Windows File Systems**: Fully sanitizes path tracking formats to ensure reliable local handling.

## Support & Maintenance
**This repository is provided "as-is" for archival purposes.** I am not actively looking for feedback, feature requests, or bug reports. The issue tracker is disabled, and I will not be responding to inquiries regarding setup or usage.

## Disclaimer
*This script automates file system directory checks and targeted file transfers. While designed for strict structural verification, always ensure you maintain separate cold storage backups of your primary volumes. The author is not responsible for any accidental data loss, incorrect configurations, or path mismatches resulting from runtime application execution.*

---
> **Document Control**<br>
> *This document is up-to-date with the following version of HashSync.*<br>
> *2026.07.02__14.27.13*