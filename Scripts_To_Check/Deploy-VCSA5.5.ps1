param([Parameter(Mandatory=$True)][String]$OvaName,
	  [Parameter(Mandatory=$True)][String]$Cluster,
	  [Parameter(Mandatory=$True)][String]$Datastore,
	  [Parameter(Mandatory=$True)][String]$PortGroupName,
	  [Parameter(Mandatory=$True)][String]$ApplianceName,
	  [Parameter(Mandatory=$False)][Switch]$DHCP,
	  [Parameter(Mandatory=$False)][String]$Domain,
	  [Parameter(Mandatory=$False)][String]$IP,
	  [Parameter(Mandatory=$False)][String]$Gateway,
	  [Parameter(Mandatory=$False)][String]$Netmask,
	  [Parameter(Mandatory=$False)][String[]]$DnsServers)

$ErrorActionPreference="Stop"

#Checking that the user is connected to any VC
if ((Test-IsVcConnected) -eq $false) {
	Write-Host "No VC Connected. Exiting..." -ForegroundColor Red
	exit 1
}

if ((Test-isVmExists $ApplianceName) -eq $true) {
	Write-Host "VM Already exists...aborting" -ForegroundColor Red
	exit 1
}

$ovfConfig = Get-OvfConfiguration $OvaName

$ovfconfig.Common.vami.hostname.Value = ($ApplianceName + "." + $Domain)
$ovfConfig.NetworkMapping.Network_1.Value = $PortGroupName
$ovfconfig.IpAssignment.IpProtocol.Value = "IPv4"
if ($DHCP -ne $true) {
	Write-Host "Static"
	$ovfconfig.vami.VMware_vCenter_Server_Appliance.gateway.Value = $Gateway
	
	$ovfconfig.vami.VMware_vCenter_Server_Appliance.DNS.Value = ""
	$i=1
	foreach ($currDns in $DnsServers) {
		$ovfconfig.vami.VMware_vCenter_Server_Appliance.DNS.Value += $currDns
		if ($i -lt $($DnsServers.count)) {
			$ovfconfig.vami.VMware_vCenter_Server_Appliance.DNS.Value += ","
		}
		$i++
	}
	$ovfconfig.vami.VMware_vCenter_Server_Appliance.ip0.Value = $IP
	$ovfconfig.vami.VMware_vCenter_Server_Appliance.netmask0.Value = $NetMask
}
else {
	Write-Host "DHCP"
}

Import-VApp -Source $OvaName -ovfConfiguration $ovfConfig -Name $($ApplianceName) -VMHost $(Get-Cluster ($Cluster) | Get-VMHost | Get-Random) -Datastore $(Get-Datastore ($Datastore)) -DiskStorageFormat Thick