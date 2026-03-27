# EverpureCloud-Retrieve-Replicated-VMs-From-Vault

# ASR Replicated VMs Export

PowerShell script to export all replicated VMs from an Azure Recovery Services Vault to a CSV file, including disk details (name, type, size).

## Prerequisites

- PowerShell 5.1 or later
- Azure PowerShell module `Az` installed
```powershell
Install-Module Az -Scope CurrentUser
```

- Sufficient Azure RBAC permissions:
  - `Reader` on the Recovery Services Vault
  - `Reader` on the source disks (for disk size retrieval)

## Authentication
```powershell
Connect-AzAccount
Set-AzContext -SubscriptionId "<SubscriptionId>"
```

## Usage

1. Clone the repository
```bash
git clone <repository-url>
cd <repository-folder>
```

2. Edit the parameters at the top of the script
```powershell
$resourceGroupName = "your-resource-group"
$vaultName         = "your-vault-name"
```

3. Run the script
```powershell
.\Export-ASRReplicatedVMs.ps1
```

## Output

A CSV file is generated in the current directory with the following naming convention:
```
ASR_<VaultName>_<VaultRegion>.csv
```

Example: `ASR_rsv-asr-demo_WestEurope.csv`

### CSV Columns

| Column | Description |
|---|---|
| `VMName` | Friendly name of the replicated VM |
| `ProtectionState` | Current ASR protection state |
| `ReplicationHealth` | Replication health status |
| `DiskName` | Name of the disk |
| `DiskId` | Full ARM resource ID of the source disk |
| `DiskType` | Disk SKU type (e.g. Premium_LRS, Standard_LRS) |
| `DiskSizeGB` | Size of the disk in GB |

### Protection States

| Value | Description |
|---|---|
| `Protected` | VM is actively replicated |
| `UnprotectedStatesBegin` | Protection is being configured |
| `FailoverCommitted` | Failover has been committed |
| `Inaccessible` | Disk could not be read (permissions or deleted source) |

## Notes

- This script uses `Invoke-AzRestMethod` to query the ASR REST API directly, bypassing the `Set-AzRecoveryServicesAsrVaultContext` cmdlet which may throw an _"Object reference not set"_ error in some environments.
- Disk size is retrieved individually per disk via `Get-AzDisk`. For vaults with a large number of replicated VMs, execution time may increase accordingly.
- If a disk size cannot be retrieved (deleted source, insufficient permissions), the `DiskSizeGB` field will show `Inaccessible`.

## Tested With

| Component | Version |
|---|---|
| Az.RecoveryServices | 7.11.1 |
| PowerShell | 5.1+ |
| Azure API version | 2023-08-01 |
