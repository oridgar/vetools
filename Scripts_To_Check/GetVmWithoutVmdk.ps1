$Result = @()
$InitialLocation = Get-Location
Set-Location vmstore:\
$DataCenterList =  Get-ChildItem
foreach ($currDataCenter in $DatacenterList) {
	Write-Host "Current DataCenter: $($currDataCenter.name)"
	Set-Location $currDataCenter
	$DataStoreList = Get-ChildItem
	foreach ($currDatastore in $DataStoreList) {
		Write-Host "Current DataStore: $($currDataStore.name)"
		Set-Location $currDatastore
		$VmDirList = Get-ChildItem
		foreach ($currVmDir in $VmDirList) {
			#Write-Host "Current VM: $($currVmDir.name)"
			if (($currVmDir.ItemType -ne "Folder") -or ( $currVmDir.Name -eq ".sdd.sf")) {
				Continue
			}
			Set-Location $currVmDir
			$VmFileList = Get-ChildItem
			$vmdkList = $VmFileList | where-object {$_.ItemType -eq "VmDiskFile"}
			$vmx = $VmFileList | where-object {$_.Name -match "vmx$"}
			if ($vmx -ne $null) {
				Write-Host "VM is $($vmx.name)" -ForegroundColor Blue
				$currItem = "" | Select VM, Datastore, vmdkExist
				$currItem.VM = $vmx.Name
				$currItem.Datastore = $currDatastore.Name
				
				if ($vmdkList -eq $null) {
					Write-Host "VM $vmx does not have any vmdk" -ForegroundColor Red
					$currItem.vmdkExist = $false
				}
				else {
					$currItem.vmdkExist = $true
				}
				$Result += $currItem
			}
			Set-Location ..
		}
		Set-Location ..
	}
	Set-Location ..
}
Set-Location $InitialLocation
return $Result