﻿param (
    [Parameter(Mandatory=$false)] [string] $sourceStorageAccountName="azuresmokestorageaccount",
    [Parameter(Mandatory=$false)] [string] $sourceRG="azuresmokeresourcegroup",
    [Parameter(Mandatory=$false)] [string] $destRG="azuresmokeresourcegroup",
    [Parameter(Mandatory=$false)] [string] $destContainer="clean-vhds",
    [Parameter(Mandatory=$false)] [string] $location="westus"
)

$copyblobs_array=@()
$copyblobs = {$copyblobs_array}.Invoke()

Write-Host "Importing the context...." -ForegroundColor Green
Import-AzureRmContext -Path 'C:\Azure\ProfileContext.ctx'

Write-Host "Selecting the Azure subscription..." -ForegroundColor Green
Select-AzureRmSubscription -SubscriptionId "2cd20493-fe97-42ef-9ace-ab95b63d82c4"
Set-AzureRmCurrentStorageAccount –ResourceGroupName $destRG –StorageAccountName $sourceStorageAccountName

Write-Host "Getting the list of machines and disks..."  -ForegroundColor green
$smoke_machines=Get-AzureRmVm -ResourceGroupName $sourceRG
$smoke_machines | Stop-AzureRmVM -Force
Get-AzureRmDisk -ResourceGroupName $sourceRG 

Write-Host "Launching jobs for validation of individual machines..." -ForegroundColor Yellow

foreach ($machine in $smoke_machines) {
    $vhd_name = $machine.Name + ".vhd"
    $vmName = $machine.Name

    $uri=$machine.StorageProfile.OsDisk.Vhd.Uri
    
    Write-Host "Initiating job to copy VHD $vhd_name from cache to working directory..." -ForegroundColor Yellow
    $blob = Start-AzureStorageBlobCopy -AbsoluteUri $uri -destblob $vhd_name -DestContainer $destContainerName -DestContext $context -Force

    $copyblobs.Add($vhd_name)
}

Write-Host "All jobs have been launched.  Initial check is:" -ForegroundColor Yellow

foreach ($blob in $copyblobs) {
    $status = Get-AzureStorageBlobCopyState -Blob $blob -Container $destContainerName -WaitForComplete

    $status
}

write-host "All done!"