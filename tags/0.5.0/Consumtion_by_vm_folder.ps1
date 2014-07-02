Param([Parameter(Mandatory=$true)] $OutputFilePath)
$sumdata = @()

Write-Host "Getting all Folders" -ForegroundColor Yellow
 #get-datacenter | get-folder -type VM | where-object {$_.parent -like "Israel*"} | get-folder | where-object { $_.parent -like "vm*"} | 
 
get-datacenter | get-folder -type VM | where-object { $_.parent -like "vm*" -or $_.name -like "vm*"} |
	ForEach-Object {
  	$Folder = $_
  
 	if ($Folder.name -eq "vm")
  	{
  		$global:VMs = $Folder | Get-VM -NoRecursion
		$global:Datacenter = $Folder.parent.tostring()
	}
	else
	{
		$global:VMs = $Folder | Get-VM 
		$global:Datacenter = $Folder.parent.parent.tostring()
	}
	
  
  Write-host "Getting Data of current folder" $Folder.name -ForegroundColor Blue
  $sumdata += $Folder | Select-Object -Property Name,
    @{N="DataCenter";E={$Datacenter}},
    @{N="TotalNumCpu";E={$VMs | Measure-Object -Property NumCpu -Sum | Select-Object -ExpandProperty Sum}},
    @{N="TotalMemoryGB";E={$VMs | Measure-Object -Property MemoryGB -Sum | Select-Object -ExpandProperty Sum}},
	@{N="TotalUsedSpaceGB";E={$VMs | Measure-Object -Property UsedSpaceGB -Sum | Select-Object -ExpandProperty Sum}},
	@{N="TotalProvisionedSpaceGB";E={$VMs | Measure-Object -Property ProvisionedSpaceGB -Sum | Select-Object -ExpandProperty Sum}},
	@{N="TotalVMs";E={$VMs | Measure-Object | Select-Object -ExpandProperty Count}}
}
$sumdata | Export-Csv $OutputFilePath -NoTypeInformation