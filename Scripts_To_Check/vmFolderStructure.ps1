

function Get-Objects($Folder) {
	#Write-Host "Folder: " $Folder.Name
	#Write-Host "-----------------------------"
	$vmList = Get-VM -Location $Folder -NoRecursion
	foreach ($currVm in $vmList) {
		"" | select @{N="Type";E={"VM"}},@{N="Name";E={$currVm.Name}},@{N="Parent";E={$Folder.Name}}
	}
	$subFolders = Get-Folder -Location $Folder
	#$subFolders
	foreach ($currSubFolder in $subFolders) {
			"" | select @{N="Type";E={"Folder"}},@{N="Name";E={$currSubFolder.Name}},@{N="Parent";E={$Folder.Name}}
			Get-Objects($currSubFolder)
	}
}

$rootfolder = Get-Folder -Name vm -Type VM
Get-Objects($rootfolder)

