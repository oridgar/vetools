<#*************************************************************************************
This file is part of veTools.
Copyright (c) 2013-2014 by Or Idgar.

veTools is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

veTools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Transmission Remote GUI; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
*************************************************************************************#>

function DeployVM {
param([Parameter(Mandatory=$true)]$IP,`
	  [Parameter(Mandatory=$true)]$NetMask,`
	  [Parameter(Mandatory=$true)]$GateWay,`
	  [Parameter(Mandatory=$true)]$VMName,`
	  [Parameter(Mandatory=$false)]$PortGroup,`
	  [Parameter(Mandatory=$false)]$Template,`
	  [Parameter(Mandatory=$false)]$clusterName,`
	  [Parameter(Mandatory=$false)]$DS,`
	  [Parameter(Mandatory=$false)]$Custom,`
	  [Parameter(Mandatory=$false)]$VMFolder,`
	  [Parameter(Mandatory=$false)][Boolean]$WhatIf=$false)

	#------------
	#Code Section
	#------------
	$ErrorActionPreference = "Stop"
	Clear-Host
	try {
		if ((Test-IsVcConnected) -eq $false) {
			Write-Host "You are not currently connected to any servers. Please connect first using a Connect cmdlet." -ForegroundColor Red
			exit 1
		}
		
		# --------------------------
		# Interactive fields filling
		# --------------------------
		Write-Host "Check if the VM $($VMName) is already exists..." -NoNewline
		$newVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
		if ($newVM -eq $null) {
			Write-Host "Not Exist" -ForegroundColor Green
		}
		else {
			Write-Host "Exists" -ForegroundColor Yellow
			$deleteAnswer = Read-Host -Prompt "Do you want to delete this VM?[Yes/No]"
			if ($deleteAnswer -eq "Yes") {
				try {
					$newVM | Stop-VM -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
				}
				catch [System.Exception] {}
				$newVM | Remove-VM -DeletePermanently:$true -Confirm:$true | Out-Null
				if ($? -eq $true) {
					$newVM = $null
				}
			}
			else {
				exit 1
			}
		}
		
		if ((Test-IsIpExists $IP) -eq $true) {
			Write-Host "Warning, IP already exists in the network!" -ForegroundColor Yellow
			Write-Host
		}
		
		if ($PortGroup -eq $null) {
			$pgList = Get-VirtualPortGroup -Distributed | Where-Object {$_.Name -notlike "*DVUplink*"} | Select Name
			$PortGroup = Print-Menu -ObjectType "VLAN/Port Group" -ObjectList $pgList -PropertyName "Name"
		}
		
		if ($clusterName -eq $null) {
			$clusterList = Get-Cluster | Select-Object Name
			$ClusterName = Print-Menu -ObjectType "Cluster" -ObjectList $clusterList -PropertyName "Name"
		}
		$cluster= (Get-Cluster $clusterName)
		
		if ($DS -eq $null) {
			#$dsList = Get-Datastore | Select-Object Name
			$dsList += Get-DatastoreCluster | Select-Object Name
			$DS = Print-Menu -ObjectType "Datastore" -ObjectList $dsList -PropertyName "Name"
		}
			
		if ($Template -eq $null) {
			$templateList = Get-Template | Select-Object Name
			$Template = Print-Menu -ObjectType "Template" -ObjectList $templateList -PropertyName "Name"
		}

		if ($Custom -eq $null) {
			$customList = Get-OSCustomizationSpec | Select-Object Name
			$Custom = Print-Menu -ObjectType "Customization" -ObjectList $customList -PropertyName "Name"
		}
		
		if ($VMFolder -eq $null) {
			$VMFolderList = get-folder -Type VM -Location (Get-Folder -Name "vm") -NoRecursion
			$VMFolder = Print-Menu -ObjectType "VM Folder" -ObjectList $VMFolderList -PropertyName "Name"
		}
		
		$DSCluster = (Get-DatastoreCluster $DS)
		$VMFolderobj = (Get-Folder $VMFolder)
		
		if ($newVM -eq $null) {
			try {
				Get-OSCustomizationSpec -Name ("Customization for " + $VMName) -ErrorAction SilentlyContinue | Remove-OSCustomizationSpec -Confirm:$false | Out-Null
			}
			catch [System.Exception] {}
			Write-Host -NoNewline "Creating new Customization specification..."
			$newCustomSpec =  New-OSCustomizationSpec -OSCustomizationSpec $custom -Name ("Customization for " + $VMName)
			Write-Status $?
			
			Write-Host -NoNewline "Configuring network settings..."
			#$newCustomNicMapping = $newCustomSpec | Get-OSCustomizationNicMapping | Remove-OSCustomizationNicMapping -Confirm:$false
			$newCustomSpec | Get-OSCustomizationNicMapping | Remove-OSCustomizationNicMapping -Confirm:$false | Out-Null
			#TODO - Check if the customization is valid
			$newCustomSpec | New-OSCustomizationNicMapping -IpMode UseStaticIP -Position 1 -IpAddress $IP -SubnetMask $NetMask -Dns @("10.76.8.41","10.76.8.42") -DefaultGateway $GateWay | Out-Null
			Write-Status $?
			
			Write-Host -NoNewline "Deploy new VM from template with customization..."
			#$newVM = new-vm -name $VMName -datastore $DSCluster -resourcepool $cluster -template $Template -oscustomizationspec $Custom -WhatIf:$WhatIf
			$newVM = new-vm -name $VMName -datastore $DSCluster -resourcepool $cluster -template $Template -oscustomizationspec $newCustomSpec -Location $VMFolderobj
			Write-Status $?
		}
		
		if ($newVM -ne $null) {
			Write-Host -NoNewline "Setting Port group..."
			$newVM | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $PortGroup -Confirm:$false | Out-Null
			Write-Status $?
			
			if ($newVM.PowerState -ne "PoweredOn") {
				Write-Host -NoNewline "Start VM..."
				Start-VM $newVM | Out-Null
				Write-Status $?
			}

			#will automatically changed by sysprep/customization:
			#IP
			#Server Name
			#Domain
			#Local administrator Password
		}
		
		Write-Host -NoNewline "Removing the temporary customization spec..."
		if ($newCustomSpec -ne $null) {
			$newCustomSpec | Remove-OSCustomizationSpec -Confirm:$false
		}
		Write-Status $?
		
		$sysprepResult = StartVMAndWaitForSysprep -vmRef $newVM
		Write-Host "The VM $($VMName) is ready!" -ForegroundColor Green
	}
	catch [System.Exception] {
		$_.Exception.Message
		#Choose what to do - if to leave the VM as is or delete
		exit 1
	}
}