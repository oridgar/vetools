param([Parameter(Mandatory=$True)][String]$InputFile,
	  [Parameter(Mandatory=$False)][String]$Password,
	  [Parameter(Mandatory=$False)][String]$DomainAdmin,
	  [Parameter(Mandatory=$False)][String]$DomainAdminPasword)

$ErrorActionPreference="Stop"
$TaskList = @()

if ((Test-IsVcConnected) -eq $false) {
	Write-Host "No VC Connected. Exiting..." -ForegroundColor Red
	exit 1
}

try {
	$VmList = Import-Csv $InputFile
}
catch [Exception] {
	throw "File $($InputFile) not found"
}

if ($VmList.gettype().name -eq "PSCustomObject") {
	$tempArr = @()
	$tempArr += $VmList
	$VmList = $tempArr
}

if ($VmList.count -eq 0) {
	throw "no lines in file"
}


Write-Host "There are $($VmList.count) VMs in the list"

for($i=0; $i -lt $VmList.count; $i++) { 
	$currVm = $VmList[$i]
	Write-Host "Creating VM #$($i): $($currVm.Name)"
	try {
		if (($currVm.Deployed) -eq "Yes"  ) {
			Write-Host "VM $($currVM.VMName) already deployed. Skipping..." -ForegroundColor Yellow
			continue
		}
		
		if ((Get-View -ViewType VirtualMachine -Filter @{"Name"="^$($currVm.Name)$"} -Property @("Name")) -ne $null  ) {
			Write-Host "VM $($currVM.VMName) already exists. Skipping..." -ForegroundColor Yellow
			continue
		}
		
		if ($currVm.Template -ne "") {
			Write-Host "Deploy From Template" -ForegroundColor Cyan
			$TaskList = New-VM -template $($currVm.Template) -name $($currVm.Name) -datastore $($currVm.Datastore) -ResourcePool $(Get-Cluster $currVm.Cluster) -RunAsync
			#Remember to change port group
		}
		
		if ($currVm.Ova -ne "" -and $currVm.Ova -ne $null) {
			Write-Host "Deploy From OVA" -ForegroundColor Cyan
			$ovfConfig = Get-OvfConfiguration $currVm.Ova
			
			$ovfconfig.Common.vami.hostname.Value = $currVm.Name
			$ovfConfig.NetworkMapping.Network_1.Value = $currVm.PortGroup
			$ovfconfig.IpAssignment.IpProtocol.Value = "IPv4"
			if ($currVm.IpAssign -eq "Static") {
				Write-Host "Static"
				$ovfconfig.vami.VMware_vCenter_Server_Appliance.gateway.Value = $currVm.Gateway
				$ovfconfig.vami.VMware_vCenter_Server_Appliance.DNS.Value = ($currVm.DNS1 + "," + $currVm.DNS2)
				$ovfconfig.vami.VMware_vCenter_Server_Appliance.ip0.Value = $currVm.IP
				$ovfconfig.vami.VMware_vCenter_Server_Appliance.netmask0.Value = $currVm.Netmask
			}
			else {
				Write-Host "DHCP"
			}
			
			Import-VApp -Source $($currVm.OVA) -ovfConfiguration $ovfConfig -Name $($currVm.Name) -VMHost $(Get-Cluster ($currVm.Cluster) | Get-VMHost | Get-Random) -Datastore $(Get-Datastore ($currVm.Datastore)) -DiskStorageFormat Thick
		}
	}
	catch [Exception] {
		Write-host "Could not create the VM" -ForegroundColor Red
	}
}