#################################

# Connect to your Azure Account #

#################################

Connect-AzAccount


####  /!\   Don't forget to setup those parameters     /!\     ####
#### $resourceGroupName is the Resource Group where the Vault has been provisionned ####
#### $vaultName is the name of the Vault to scan ####

$resourceGroupName = ""
$vaultName         = ""

# Get Vault
$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
$subscriptionId = (Get-AzContext).Subscription.Id

# Retrieve All replicated VMs from the Vault
$uri = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.RecoveryServices/vaults/$vaultName/replicationProtectedItems?api-version=2023-08-01"

$response = Invoke-AzRestMethod -Path $uri -Method GET
$items = ($response.Content | ConvertFrom-Json).value

# List all managed disks for each Virtual Machine replicated 
$report = foreach ($item in $items) {
    $disks = $item.properties.providerSpecificDetails.protectedManagedDisks

    if ($disks) {
        foreach ($disk in $disks) {
            # Récupérer la taille via l'ID du disque source
            $diskSizeGB = "N/A"
            if ($disk.diskId) {
                try {
                    $managedDisk = Get-AzDisk -ResourceGroupName ($disk.diskId -split '/')[4] `
                                              -DiskName ($disk.diskId -split '/')[-1] `
                                              -ErrorAction Stop
                    $diskSizeGB = $managedDisk.DiskSizeGB
                } catch {
                    $diskSizeGB = "Inaccessible"
                }
            }

            [PSCustomObject]@{
                VMName            = $item.properties.friendlyName
                ProtectionState   = $item.properties.protectionState
                ReplicationHealth = $item.properties.replicationHealth
                DiskName          = $disk.diskName
                DiskId            = $disk.diskId
                DiskType          = $disk.diskType
                DiskSizeGB        = $diskSizeGB
            }
        }
    } else {
        [PSCustomObject]@{
            VMName            = $item.properties.friendlyName
            ProtectionState   = $item.properties.protectionState
            ReplicationHealth = $item.properties.replicationHealth
            DiskName          = "N/A"
            DiskId            = "N/A"
            DiskType          = "N/A"
            DiskSizeGB        = "N/A"
        }
    }
}

# Format CSV name
$vaultRegion = $vault.Location -replace '\s', ''
$csvPath = ".\ASR_$($vault.Name)_$($vaultRegion).csv"

# Export all data on the CSV file in the current directory
$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Export done : $csvPath"
