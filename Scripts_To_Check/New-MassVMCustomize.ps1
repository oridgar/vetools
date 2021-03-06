param([Parameter(Mandatory=$True)][String]$InputFile,
	  [Parameter(Mandatory=$True)][String]$Password,
	  [Parameter(Mandatory=$True)][String]$DomainAdmin,
	  [Parameter(Mandatory=$True)][String]$DomainAdminPasword,
	  [Parameter(Mandatory=$True)][Switch]$CustomizeOnly)

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
	Write-Host "Customizign VM #$($i): $($currVm.Name)"
	if (($currVm.Deployed) -eq "No"  ) {
		Write-Host "VM $($currVM.VMName) wasn't deployed yet. Skipping..." -ForegroundColor Yellow
		continue
	}
	if (($currVm.Template) -eq "") {
		Write-Host "VM is not from template... Skipping" -ForegroundColor Yellow
		continue
	}

	if (($currVm.Customized) -eq "No") {
		try {		
			if (($currVm.IpAssign) -eq "DHCP") {
				Write-host "DCHP"
				$DHCP=$true
			}
			else {
				$DHCP=$false
			}
			
			if ($CustomizeOnly -eq $false) {
				Write-host "Changing port group and connecting at startup"
				$currVmObj = Get-VM ($currVm.Name)
				$currPgObj = Get-VDPortgroup -Name ($currVm.PortGroup) -VDSwitch ($currVm.DVS)
				$currNetAdapter =  $currVmObj | get-NetworkAdapter 
				$currNetAdapter | Set-NetworkAdapter -Portgroup $currPgObj -Confirm:$false | Out-Null
				$currNetAdapter | Set-NetworkAdapter -StartConnected:$true -Confirm:$false
			}
			
			Customize-VM -DHCP $DHCP -IP ($currVm.IP) -Netmask ($currVm.Netmask) -Gateway ($currVm.Gateway) `
				-DnsServers @(($currVm.DNS1),($currVm.DNS2)) -Password $Password -DomainName ($currVm.Domain) `
				-DomainAdmin $DomainAdmin -DomainAdminPassword $DomainAdminPassword -FullName ($currVm.FullName) `
				-OrgName ($currVm.OrgName) -VM (Get-VM ($currVm.Name)) -ChangeSID="true" -ProductID ""
		}
		catch [Exception] {
			Write-Host "Could not customize the VM" -ForegroundColor Red
			$_
		}
	}
	else {
		Write-Host "VM is already customized... Skipping" -ForegroundColor Yellow
		continue
	}
}