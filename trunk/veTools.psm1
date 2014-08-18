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



#--------------------------------------------------------------------------------
#-Written by: Or Idgar																				-
#-Date: 2013																				-
#-																				-
#--------------------------------------------------------------------------------

function Get-veToolsVersion () {
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	return "0.5"
}

# Initialization
if (Get-Variable -Name veVersion -Scope Global -ErrorAction SilentlyContinue) {
	Remove-Variable veVersion -Scope Global -Force 
}
Set-Variable -Name veVersion -Scope Global -Value $(Get-veToolsVersion) -Option ReadOnly

function Write-Status ([Parameter(Mandatory=$true)] [Boolean]$result)
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	$returncode = 0
	if ($result -eq $TRUE) {write-host -ForegroundColor Green "[Succeed]"} else {write-host -ForegroundColor Red "[Failed!]"; $returncode = 1}
}

function Connect-Virtual ()
{
  <#
  .SYNOPSIS
  Connecting to virtual environment.
  .DESCRIPTION
  Connecting to both VCD and vSphere environment. 
  #>
	
	# --------------------
	# Variable Decleration
	# --------------------
	$returncode = 0
	$password = $null

	# ------------
	# Code Section
	# ------------
	
	# Getting the password for the administrator user.
	$password = Read-Host -AsSecureString "Enter" $veUser "password"
	
	# Checks if the current session is already connected to vSphere.
    if ($global:DefaultVIServers.count -eq 0 -or $global:DefaultVIServers.count -eq $null)
	{
		write-host -NoNewline "Connecting to vCenter Server(s)..."
		connect-viserver -user $veUser -password ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) -server $veVCList  2>&1> $null
	    Write-Status ($?)
		#if ($? -eq $TRUE) {write-host -ForegroundColor Green "[Succeed]"} else {write-host -ForegroundColor Red "[Failed!]"; $returncode = 1}
	}
    write-host -NoNewline "Connecting to vCloud Director..."
    connect-ciserver -user $veUser -password ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) -server $veVCDName 2>&1>$null
    Write-Status ($?)
	#if ($? -eq $TRUE) {write-host -ForegroundColor Green "[Succeed]"} else {write-host -ForegroundColor Red "[Failed!]"; $returncode = 1}
	return $returncode > $null
}

function Disconnect-Virtual ()
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	Disconnect-VIServer * -Confirm:$false -Force
}

function Get-VIServices ($viserver, $credential)
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>

	If ($credential){
        $Services = get-wmiobject win32_service -Credential $credential -ComputerName $viserver | Where {$_.DisplayName -like "VMware*" }
    } Else {
        $Services = get-wmiobject win32_service -ComputerName $viserver | Where {$_.DisplayName -like "VMware*" }
    }
 
    $myCol = @()
    Foreach ($service in $Services){
        If ($service.StartMode -eq "Auto") {
            if ($service.State -eq "Stopped") {
                $MyDetails = New-Object -TypeName PSObject -Property @{
                    Name = $service.Displayname
                    State = $service.State
                    StartMode = $service.StartMode
                    Health = "Unexpected State"
                }
            }
        }
 
        If ($service.StartMode -eq "Auto") {
            if ($service.State -eq "Running") {
                $MyDetails = New-Object -TypeName PSObject -Property @{
                    Name = $service.Displayname
                    State = $service.State
                    StartMode = $service.StartMode
                    Health = "OK"
                }
            }
        }
        If ($service.StartMode -eq "Disabled"){
            If ($service.State -eq "Running"){
                $MyDetails = New-Object -TypeName PSObject -Property @{
                    Name = $service.Displayname
                    State = $service.State
                    StartMode = $service.StartMode
                    Health = "Unexpected State"
                }
            }
        }
        If ($service.StartMode -eq "Disabled"){
            if ($service.State -eq "Stopped"){
                $MyDetails = New-Object -TypeName PSObject -Property @{
                    Name = $service.Displayname
                    State = $service.State
                    StartMode = $service.StartMode
                    Health = "OK"
                }
            }
        }
        $myCol += $MyDetails
    }
    $myCol
}

function Get-veOrgUsage ([Parameter(Mandatory=$True)] [string]$Organization)
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>

	# --------------------
	# Variable Declaration
	# --------------------
	$template_loc = $TemplatesDir
	$excelobj = New-Object -ComObject excel.application

	#------------
	#Code Section
	#------------

	#connect-virtual
	#if ($? -eq $true) {Write-Host "Done!"} else {Write-Host "Failed!"}
	Write-Host -NoNewline "Getting $Organization Data..."
	$OrgUsage = Get-OrgVdc | where-object {$_.name -eq $organization} | `
			    select name,`
						cpuallocationghz,cpuusedghz,@{Name="CpuPercentUsed";Expression={'{0:N4}' -f ($_.cpuusedghz / $_.cpuallocationghz)}},`
						memoryallocationgb,memoryusedgb,@{Name="MemoryPercentUsed";Expression={'{0:N4}' -f ($_.memoryusedgb / $_.memoryallocationgb)}},`
						storagelimitgb,storageusedgb,@{Name="StoragePercentUsed";Expression={'{0:N4}' -f ($_.storageusedgb / $_.storagelimitgb)}},`
						vmmaxcount,@{N="VMCount";E={($_ | Get-CIVM).count}},@{Name="VMPercentUsed";Expression={'{0:N4}' -f (($_ | Get-CIVM).count / $_.vmmaxcount)}} -unique

	# Open the excel template
	$excelobj.visible = $true
	$excelworkbook = $excelobj.workbooks.open(($template_loc + "\OrgUsageReportTemplateV2.xlsx"))
	$currworksheet = $excelworkbook.worksheets.item(1)

	# For each organization will change values.
	foreach ($currorg in $OrgUsage)
	{
			$currworksheet.cells.item(2,2) = $Organization
			$currworksheet.cells.item(4,3) = $currorg.cpuallocationghz #(row,column)
			$currworksheet.cells.item(4,4) = $currorg.cpuusedghz
			$currworksheet.Cells.Item(5,3) = $currorg.memoryallocationgb
			$currworksheet.Cells.Item(5,4) = $currorg.memoryusedgb
			$currworksheet.Cells.Item(6,3) = $currorg.storagelimitgb
			$currworksheet.Cells.Item(6,4) = $currorg.storageusedgb
			$currworksheet.Cells.Item(7,3) = $currorg.vmmaxcount
			$currworksheet.Cells.Item(7,4) = $currorg.VMCount
	}

	# Color whole row

	#$objRange = $objExcel.ActiveCell.EntireRow
	#$objRange.Cells.Interior.ColorIndex = 37

	#$Currworksheet.Cells(i, 1).Font.ColorIndex = 3
	
	$date = Get-Date
	# Saving the new report and quit excel.
	$excelworkbook.SaveAs($ReportDir + $(Get-SortedDate) + "-" + $Organization + ".xlsx")
	$excelobj.Quit()
	while( [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelobj)){}
	Write-Host -ForegroundColor Green "Done!"
}

function Get-veVcdOversized ([Parameter(Mandatory=$true)] [string]$oversized_File,[Parameter(Mandatory=$true)] $outputpath)
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	
	# Variable Decleration
	$Result = @()
	$Errorlist = @()

	# Code Section
	# ------------

	#[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
	# Out-Null

	#Import-Module "C:\Users\Or.BENEFIT\Documents\General Scripts\genfuncs.psm1"

	clear
	# Connecting to VC and VCD
	#connect-virtual

	# Reading excel to enrich

	#Write-Host "Choose vcops oversized csv file"
	#$vcops_oversized_file = New-Object system.windows.forms.openfiledialog
	#$vcops_oversized_file.InitialDirectory = 'c:\Users\Or.BENEFIT\Documents'
	#$vcops_oversized_file.MultiSelect = $false
	#$vcops_oversized_file.showdialog()


	write-host "Getting Data"
	$vcops_vms = import-csv $oversized_File
	#$vcops_vms = import-csv $vcops_oversized_file.filename

	$vcops_vms_count = $vcops_vms.Count
	write-host "Found $vcops_vms_Count oversized VMs"

	# Reading all VMs in vCloud Director
	$vcloud_vms = get-ciVM

	# Looping on all cloud VMs
	$counter = 0
	write-host "`nLooping on all cloud VMs"
	Write-Host   "------------------------"
	foreach ($curr_vm in $vcops_vms)
	{
	    # Looping on all VMs from the excel
	    foreach ($curr_cloudvm in $vcloud_vms)
	    {
	        # extract uuid from objects.
			$vcops_vm_uuid = $curr_vm."Virtual Machine".split(" ")[-1].TrimStart("(").TrimEnd(")")
			$vcops_vm_name = $curr_vm."Virtual Machine".split(" ")[0]
			$vcd_vm_uuid = $curr_cloudvm.id.substring(14,36)
			
			# filtering Cloud VMs and adding data to result array.
	        if ($vcops_vm_uuid  -eq $vcd_vm_uuid)
	        {    
	            $counter++ #Raising Current VM counter.
				if ($counter -gt 10)
				{
					write-host -NoNewline "`b"
				}
				if ($counter -gt 100)
				{
					Write-Host -NoNewline "`b"
				}
				if ($counter -gt 1000)
				{
					Write-Host -NoNewline "`b"
				}
				
				write-host -NoNewline "`b$counter"
			
				if ($curr_cloudvm.VApp.Org -eq $null)
				{
					$Errorlist += $curr_vm
				}
				else
				{
					# Creating new object for new row in the array.
					$vm_detail = new-object psobject -property `
		                @{'Organization'=$curr_cloudvm.VApp.Org.tostring();`
		                  'Owner'=$curr_cloudvm.VApp.owner.tostring(); `
		                  'vApp'=$curr_cloudvm.VApp.name.tostring(); `
		                  'VM'=$vcops_vm_name;
						  'Configured Memory'=$curr_vm."Configured Memory";
						  'Configured vCPU'=$curr_vm."Configured vCPU"; `
		                  'CPU Demand of Recommended(%)'=$curr_vm."CPU Demand of Recommended(%)";
						  'Recommended Memory'=$curr_vm."Recommended Memory";
						  'Recommended vCPU'=$curr_vm."Recommended vCPU"
						  }
					# Adding to the results array the current row.
					$Result += $vm_detail
				}
				break #exit in order to bring efficiency.
	        }
	    }
	}

	#Write-Host "Choose output folder"
	#$outputfolder = New-Object System.Windows.Forms.FolderBrowserDialog
	#$outputfolder.showdialog()

	$outputfile = Read-Host "Enter report file name"
	$Result | select * | Sort-Object Organization,Owner,vApp,VM
	$Result | Export-Csv -NoTypeInformation -Path ("$outputpath" + "\" + "$outputfile" + ".csv")
	$Errorlist | Export-Csv -NoTypeInformation -Path ("$outputpath" + "\" + "$outputfile" + ".errors.csv")
}

function Get-veUserOrg ([Parameter(Mandatory=$true)] [string]$fullname)
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	Get-CIUser | Where-Object {$_.fullname -eq $fullname} | Select-Object name,org
}

function Reload-veTools ()
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	Remove-Module veSettings
	Remove-Module veTools
	Import-Module veSettings
	Import-Module veTools
}

function get-veOrgByFullName ([Parameter(Mandatory=$true)] [string]$fullname)
{
  <#
  .SYNOPSIS
  Getting Organization name by full name
  .DESCRIPTION
  Getting the vCloud Director Organization name by full name
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER fullname
  Organization full name.
  #>
	get-org | where-object {$_.fullname -eq $fullname} | select name
}

function Get-veClusterDSShared ([Parameter(Mandatory=$true)] [string]$ClusterName)
{
  <#
  .SYNOPSIS
  Getting all the shared datastores on specific cluster
  .DESCRIPTION
  Getting the vCloud Director Organization name by full name
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER fullname
  Organization full name.
  #>
  Get-Cluster $ClusterName | Get-VMHost | Get-Datastore | select Name -Unique | `
  Where-Object {!($_.Name -like  "*Local*")}
}
function Get-veVMbyExtIP ([Parameter(Mandatory=$true)] [string]$ExternalIP)
{
  <#
  .SYNOPSIS
  Finding which VM has specific external IP
  .DESCRIPTION
  Finding which VM has specific external IP
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER ExternalIP
  VM external IP.
  #>
   
   #Getting all the organization networks in order to map segments
   Get-OrgNetwork | select Name,Org,Gateway,Netmask,StaticIPPool,NetworkPool,NetworkType | ft -AutoSize
   
   #Find the relevant organization.
   #COMPLETE!
   $VM_ORG = ""
   
   #Getting the VM with the IP, whether if the ip is direct or NAT (Internal / External)
   Get-Org $VM_ORG | get-civapp | get-civm | Get-CINetworkAdapter | select VM,IPAddress,ExternalIPAddress | Where-Object {$_.IPAddress -eq $ExternalIP -or $_.ExternalIPAddress -eq $ExternalIP}
}

function Set-veNewOwner ([Parameter(Mandatory=$true)] [string]$OldUser,[Parameter(Mandatory=$true)] [string]$NewUser,[Parameter(Mandatory=$true)] [string]$Organization)
{
  <#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER OldUser
  
  .PARAMETER NewUser
  
  .PARAMETER Organization
  
  #>
	$OldUserObj = Get-CIUser -Name $OldUser | where-object {$_.org -like "*$Organization*"}
	$NewUserObj = Get-CIUser -Name $NewUser | where-object {$_.org -like "*$Organization*"}
	Get-Org $Organization | Get-ciVApp | where-object {$_.Owner -like "*$OldUser*"} | Set-CIVApp -Owner $NewUserObj
}

Function New-CIUser ($Name, $Pasword, $FullName, [Switch]$Enabled, $Org, $Role)
{
  <#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
    Process {
        $OrgED = (Get-Org $Org).ExtensionData
        $orgAdminUser = New-Object VMware.VimAutomation.Cloud.Views.User
        $orgAdminUser.Name = $Name
        $orgAdminUser.FullName = $FullName
        $orgAdminUser.Password = $Pasword
        $orgAdminUser.IsEnabled = $Enabled

        $vcloud = $DefaultCIServers[0].ExtensionData
       
        $orgAdminRole = $vcloud.RoleReferences.RoleReference | where {$_.Name -eq $Role}
        $orgAdminUser.Role = $orgAdminRole
       
        $user = $orgED.CreateUser($orgAdminUser)
        Get-CIUser -Org $Org -Name $Name
    }
} 

Function New-Org ([string]$Name, [string]$FullName, [string]$Description, [Switch]$Enabled, [Switch]$PublishCatalogs)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
    Process {
        $vcloud = $DefaultCIServers[0].ExtensionData
       
        $AdminOrg = New-Object VMware.VimAutomation.Cloud.Views.AdminOrg
        $adminOrg.Name = $name
        $adminOrg.FullName = $FullName
        $adminOrg.Description = $description
        $adminOrg.IsEnabled = $Enabled

        $orgSettings = New-Object VMware.VimAutomation.Cloud.Views.OrgSettings
        $orgGeneralSettings = New-Object VMware.VimAutomation.Cloud.Views.OrgGeneralSettings
        $orgGeneralSettings.CanPublishCatalogs = $PublishCatalogs
        $orgSettings.OrgGeneralSettings = $orgGeneralSettings

        $adminOrg.Settings = $orgSettings

        $org = $vcloud.CreateOrg($adminOrg)
        Get-Org -Name $name
    }
} 

Function New-OrgVDC ($Name, [Switch]$Enabled, $Org, $ProviderVDC, $AllocationModel, $CPULimit, `
	$CPUAllocated, $MEMAllocated, $MEMLimit, $StoraqeLimit) 
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>

    Process {
        $adminVdc = New-Object VMware.VimAutomation.Cloud.Views.AdminVdc
        $adminVdc.Name = $name
        $adminVdc.IsEnabled = $Enabled
        $providerVdc = Get-ProviderVdc $ProviderVDC
        $providerVdcRef = New-Object VMware.VimAutomation.Cloud.Views.Reference
        $providerVdcRef.Href = $providerVdc.Href
        $adminVdc.ProviderVdcReference =$providerVdcRef
        $adminVdc.AllocationModel = $AllocationModel
        $adminVdc.ComputeCapacity = New-Object VMware.VimAutomation.Cloud.Views.ComputeCapacity
        $adminVdc.ComputeCapacity.Cpu = New-Object VMware.VimAutomation.Cloud.Views.CapacityWithUsage
        $adminVdc.ComputeCapacity.Cpu.Units = "MHz"
        $adminVdc.ComputeCapacity.Cpu.Limit = $CPULimit
        $adminVdc.ComputeCapacity.Cpu.Allocated = $CPUAllocated
        $adminVdc.ComputeCapacity.Memory = New-Object VMware.VimAutomation.Cloud.Views.CapacityWithUsage
        $adminVdc.ComputeCapacity.Memory.Units = "MB"
        $adminVdc.ComputeCapacity.Memory.Limit = $MEMLimit
        $adminVdc.ComputeCapacity.Memory.Allocated = $MEMAllocated
        $adminVdc.StorageCapacity = New-Object VMware.VimAutomation.Cloud.Views.CapacityWithUsage
        $adminVdc.StorageCapacity.Units = "MB"
        $adminVdc.StorageCapacity.Limit = $StorageLimit
       
        $OrgED = (Get-Org $Org).ExtensionData
        $orgVdc = $orgED.CreateVdc($adminVdc)
        Get-OrgVdc $name
    }
}

Function SMigrate-ve_By_List ([Parameter(Mandatory=$true)] [string]$Excel,[Parameter(Mandatory=$true)] [string]$Datastore)
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
{
	# --------------------
	# Variable Decleration
	# --------------------
	
	$VMlist = Import-Csv $Excel
	$VMarr = @()

	ForEach ($curr_VM in $VMlist)
	{
		Write-Host -NoNewline -ForegroundColor Blue "Getting Virtual machine '" ($curr_VM.VM) "' ..."
		$curr_vmObj = get-vm ($curr_VM.VM)
		write-status $?
		$VMarr += $curr_vmObj
		
	}

	$VMarr
	$VMarr | move-vm -Datastore (get-datastore "$Datastore")
}

Function Delete-veSnapshot_By_List ([Parameter(Mandatory=$true)] $Excel_Name)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	
	# --------------------
	# Variable Decleration
	# --------------------
	$SnapshotArr = @()

	$Snapshots_list = Import-Csv $Excel_Name
	
	if ($? -eq $false) {break}

	Write-Host

	foreach ($curr_snapshot in $Snapshots_list) {
		Write-Host -NoNewline "Snapshot" ($curr_snapshot.Name) " For VM" ($curr_snapshot.VM) "..... " -ForegroundColor Blue
		(($curr_snapshotobj = (Get-VM -Name ($curr_snapshot.VM) | Get-Snapshot -Name $curr_snapshot.Name)) | out-null ) 2> $null
		if ($curr_snapshotobj -ne $null)
		{
			$SnapshotArr += $curr_snapshotobj
			write-host "Found!" -ForegroundColor Green
		}
		else
		{
			Write-Host "No snapshots" -ForegroundColor Red
		}
	}

	Write-Host "Total of" ($SnapshotArr.Length) " snapshots to delete"
	$SnapshotArr

	$SnapshotArr | Remove-Snapshot -RemoveChildren 
}

Function Get-veOrgComputeUsage ([Parameter(Mandatory=$true)] [string]$Org)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>

	# --------------------
	# Variable Decleration
	# --------------------
	$objects = @()

	Write-Host "getting $Org VMs"
	$vms = Get-Org -Name $Org | get-civm

	Write-Host "Summaries each VM (Total of " $vms.count ")"
	$i = 1
	foreach($vm in $vms)
	{
	 Write-Host -NoNewline "$i..."
	 $extensiondata = $vm.extensiondata
	 $has_snapshot = $extensiondata.getsnapshotsection().snapshot -ne $null
	 $hardware = $extensiondata.GetVirtualHardwareSection()
	 $diskMB = (($hardware.Item | where {$_.resourcetype.value -eq "17"}) | %{$_.hostresource[0].anyattr[0]."#text"} | Measure-Object -Sum).sum
	 if ($has_snapshot) {$totalstorage = $diskMB/1024 *2 + $vm.MemoryGB} else {$totalstorage = $diskMB/1024 + $vm.MemoryGB}
	 $cpuGhz = $vm.cpucount * 2
	# Creating new record
	 $row = New-Object PSObject -Property @{"owner"=$vm.vapp.owner;`
	 										"vapp"=$vm.vapp.name;`
											"vm_name"=$vm.Name;`
											"cpuCount"=$vm.CpuCount;`
											"cpuGhz"=$cpuGhz;`
											"memoryGB"=$vm.MemoryGB;`
											"storageGB"=($diskMB/1024);`
											"Status"=$vm.status;`
											"Organization"=$Org;`
											"Snapshot"=[string]$has_snapshot;`
											"TotalStorage"=$totalStorage}
	# Saving the record into the array
	 $objects += $row
	 ++$i
	}

	# Use select object to get the column order right. Sort by vApp. Force table formatting and auto-width.
	return $objects | select-Object owner,vapp,vm_name,cpuCount,cpuGhz,memoryGB,storageGB,status,Organization,snapshot,TotalStorage | Sort-Object -Property Organization,vapp
}

Function Get-veOrgUsers ([Parameter(Mandatory=$true)] [string]$Org)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	Get-Org -Name $Org | Get-CIUser | select Org,Name,FullName,DeployedVMCount,DeployedVMQuota,StoredVMCount,StoredVMQuota
}

Function Get-veVMFolder ([Parameter(Mandatory=$true)] $VMHost)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	 clear
	 Write-host "Searching for $VMname ...."
	 
	Try { $Folders= Get-VMHost $VMHost | Get-VM | Select Folder}
	 Catch
	 { Write-Host "Something went wrong. Are You connected to vCenter ?" -ForeGroundColor Red
	 Break
	 }
	 foreach ($FolderName in $Folders)
	 {
		 $Level=1
		 $Path = ""
		 $CurrentFolder=$FolderName.Folder
		 If ($CurrentFolder.name -eq $NULL)
		 {
		 Write-Host "$VMName is wrong or might not exist"
		 Exit
		 }
		 While ($CurrentFolder.name -ne "vm")
		 {
		 Write-host "Level($Level) : $CurrentFolder"
		 $Parent= Get-Folder $CurrentFolder | Select parent
		 $Path=$CurrentFolder.name + "\" + $Path
		 $CurrentFolder=$Parent.Parent
		 if ($CurrentFolder.count -gt 0 )
		 {$currentFolder= $CurrentFolder[0]
		 }
		 $Level=$Level + 1
		 }
		 Write-host "Final Path:" -ForeGroundColor "White" $Path
	 }
 }
 
Function Count-Inaccessible ()
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	(Get-View -ViewType VirtualMachine | ?{$_.Runtime.ConnectionState -eq "inaccessible"}).count
}

Function Set-veClusterSyslog ([Parameter(Mandatory=$true)] [string]$clustername,[Parameter(Mandatory=$true)] [string]$syslogServer)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	#Open the ports for syslog
	Get-Cluster $clustername | Get-VMHost | Sort-Object name | Get-VMHostFirewallException -Name syslog | `
		Set-VMHostFirewallException -Enabled $true

	$hosts = Get-Cluster $clustername | get-vmhost | Sort-Object name | select name
	foreach ($currhost in $hosts)
	{
		Write-Host $currhost
		Set-VMHostAdvancedConfiguration -Name Syslog.global.logHost -Value ("udp://" + $syslogServer + ":514") -VMHost ($currhost.name)
	}
}

Function Start-veESXiSSH ([Parameter(Mandatory=$true)] [string]$Hostname)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	get-vmhost -Name $Hostname | Get-VMHostService | where {$_.key -eq "TSM-SSH"} | Start-VMHostService
}

Function Reload-Inaccessible ([Parameter(Mandatory=$true)] [String]$hostname)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	
	$currid = ""
	$currhost = ""
	$VMs = $null

	Write-Host -NoNewline "Getting the id of host $hostname..."
	$currhost = get-vmhost | Where-Object {$_.name -eq $hostname}

	Write-Status ($?)

	$currid = $currhost.id

	Write-Host -NoNewline "Getting all the inaccessible Virtual Machines in $hostname..."
	$VMs = Get-View -ViewType VirtualMachine | `
			Where-Object {$_.Runtime.ConnectionState -eq "inaccessible" -and $_.Runtime.Host -eq $currid}
	Write-Status ($?)

	# Printing the names of inaccessible VMs in the current host
	#Write-Host -NoNewline "Inaccessible Virtual Machines number: "
	#$VMs.count

	if ($VMs -ne $null){
		Write-Host "Reloading " $VMs.Count.ToString() " Virtual Machines"
		#Get-View -ViewType VirtualMachine | ?{$VMs -contains $_.name}
		$VMs | foreach {$_.Reload()}
	}
}

Function Get-veToolsCommand ()
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	Get-command -Module veTools
}

Function Get-VMfolderVlans ([Parameter(Mandatory=$true)] [string]$FolderName)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	Get-Folder -Name $FolderName -Type VM | Get-VM | Get-NetworkAdapter | Get-VDPortgroup | select VlanConfiguration -Unique
}

Function Get-VMHostVmotionIP ()
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	Get-VMHost | Get-VMHostNetworkAdapter | Where-Object {$_.name -match "^vmk" -and $_.vmotionenabled -eq $true}
}

Function Get-VMfolderDatastores ([Parameter(Mandatory=$true)] [string] $FolderName)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	get-folder -name $FolderName -type VM | get-VM | get-datastore
}

Function Reconfigure-HA ([Parameter(Mandatory=$true)] [string]$ClusterName)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	Write-Host "Disabling HA on cluster $ClusterName..." -NoNewline 
	Get-Cluster -Name $ClusterName | Set-Cluster -HAEnabled:$false -Confirm:$false | Out-Null
	while ((Get-Task | Where-Object {$_.name -eq "Unconfiguring HA" -and $_.State -eq "Running"}) -ne $null) {sleep -Seconds 5; Write-Host "." -NoNewline}
	Write-Status $true
	Write-Host "Enabling HA on cluster $ClusterName..." -NoNewline
	Get-Cluster -Name $ClusterName | Set-Cluster -HAEnabled:$true -Confirm:$false | Out-Null
	while ((Get-Task | Where-Object {$_.name -eq "Configuring HA" -and $_.State -eq "Running"}) -ne $null) {sleep -Seconds 5; Write-Host "." -NoNewline}
	Write-Status $true
}

Function Get-SortedDate ()
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Name
  #>
	$Date = Get-Date
	$Day = [String]($Date.day)
	$Month = [String]($Date.month)
	$Year = [String]($Date.Year)
	return [string]$("$Year" + "-" + "$($Month.PadLeft(2,'0'))" + "-" + "$($Day.PadLeft(2,'0'))")
}


Function Set-PathsToRR ([Parameter(Mandatory=$false,ValueFromPipeline=$false,Position=0)] [string]$Filter)
{
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER Filter
  Filtering by wildcard.
  #>
  get-vmhost | sort-object -property name | Where-Object {$_.name -like $Filter} `
  	| Get-ScsiLun -LunType "disk" | where {$_.multipathpolicy -ne "RoundRobin" -and $_.model -eq "LUN" } | Set-ScsiLun -MultipathPolicy RoundRobin
}

function Copy-VCFolderStructure {
<#
    .SYNOPSIS
        Copy-VCFolderStructure copies folder and its structure from one VC to another..
 
    .DESCRIPTION
        Copy-VCFolderStructure can be handy when doing migrations of clusters/hosts between
        Virtual Center servers. It takes folder structure from 'old' VC and it recreates it on 'new'
        VC. While doing this it will also output virtualmachine name and folderid. Why would you
        want to have it ? Let's say that you have a cluster on old virtual center server
        oldvc.local.lab
        DC1\Cluster1\folder1
        DC1\Cluster1\folderN\subfolderN
        Copy-VCFolderStructure will copy entire folder structure to 'new' VC, and while doing this
        it will output to screen VMs that resides in those structures. VM name that will be shown on
        screen will show also folderid, this ID is the folderid on new VC.  After you have migrated
        your hosts from old cluster in old VC to new cluster in new VC, and folder structure is there,
        you can use move-vm cmdlet with -Location parameter. As location you would have give the
        folder object that corresponds to vm that is being moved. Property Name is the name of VM
        that was discovered in that folder and Folder is the folderid in which the vm should be moved
        into. This folderid has to first changed to folder, for example :
        $folderobj=get-view -id $folder|Get-VIObjectByVIView
        We can then use $folderobj as parameter to move-vm Location parameter
 
    .PARAMETER  OldFolder
        This should be the extensiondata of folder that you want to copy to new VC.
        $folderToRecreate=Get-Folder -Server oldVC.lab.local -Name teststruct
        Have in mind that this should be an single folder and not an array.
         
 
    .PARAMETER  ParentOfNewFolder
        When invoking the function this is the root folder where you want to attach the copied folder.
        Let's say you are copying folder from \DatacenterA\FolderX\myfolder
        If you will have the same structure on the new VC, you would have set ParentOfNew folder
        to FolderX. Still it's not a problem if you have a new structure on new VC. Let's say that on
        new VC you have folder: \DatacenterZ\NewStructure\FolderZ and you want to copy entire
        'myfolder' beneath the FolderZ. In that case, first create a variable that has desired folder
        $anchor=get-folder 'FolderZ' -Server newVC
        Make sure that $anchor variable will have only 1 element.
         
    .PARAMETER  NewVC
        This parameter describes virtual center to which we are copying the folder structure.
        Copy-VCFolderStructure works only when you are connected to both old and new vc at the
        same time. You need to set your configuration of PowerCLI to handle multiple connections.
        Set-PowerCLIConfiguration -DefaultVIServerMode 'Multiple'
        You can check if you are connected to both servers using $global:DefaultVIServers variable
 
    .PARAMETER  OldVC
        This parameter describes virtual center from which we are copying the folder structure.
        Copy-VCFolderStructure works only when you are connected to both old and new vc at the
        same time. You need to set your configuration of PowerCLI to handle multiple connections.
        Set-PowerCLIConfiguration -DefaultVIServerMode 'Multiple'
        You can check if you are connected to both servers using $global:DefaultVIServers variable
  
    .EXAMPLE
        PS C:\> Set-PowerCLIConfiguration -DefaultVIServerMode 'multiple'
        PS C:\> $DefaultVIServers
        Ensure that you are connected to both VC servers
        Establish variables:
        This will be the folder that we will be copying from old VC
        $folderToRecreate=Get-Folder -Server $OldVC -Name 'teststruct'
        This will be the folder to which we will be copying the folder structure
        $anchor=get-folder 'IWantToPutMyStructureHere' -Server $NewVC
        $OldVC='myoldvc.lab.local'
        $NewVC='mynewvc.lab.local'
        Copy-VCFolderStructure -OldFolder $folderToRecreate.exensiondata -NewVC $NewVC
        -OldVC $OldVC -ParentOfNewFolder $anchor
        $OldFolder expects to get exensiondata object from the folder, if you will not provide it, function will
        block it.
 
    .EXAMPLE
        If you are planning to move vms after hosts/vm/folders were migrated to new VC, you might use it in this way.
        By default Copy-VCFolderStructure will output also vms and their folder ids in which they should reside on new
        VC. You can grab them like this:
        $vmlist=Copy-VCFolderStructure -OldFolder $folderToRecreate.exensiondata -NewVC $NewVC
        -OldVC $OldVC -ParentOfNewFolder $anchor
        You can now export $vmlist to csv
        $vmlist |export-csv -Path 'c:\migratedvms.csv' -NoTypeInformation
        And once all virtual machines are in new virtual center, you can import this list and do move-vm operation on those
        vms. Each vm has name and folder properties. Folder is a folderid value, which has to be converted to Folder object.
        move-vm -vm $vmlist[0].name -Location (get-view -id $vmlist[0].folder -Server $newVC|get-viobjectbyviview)
        -Server $newVC
        This would move vm that was residing in previously on old VC in migrated folder to its equivalent on new VC.
 
    .NOTES
        NAME:  Copy-VCFolderStructure
         
        AUTHOR: Grzegorz Kulikowski
         
        NOT WORKING ? #powercli @ irc.freenode.net
         
        THANKS: Huge thanks go to Robert van den Nieuwendijk for helping me out with the recursion in this function.
 
    .LINK
 
https://psvmware.wordpress.com
 
#>
 
   param(
   [parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [VMware.Vim.Folder]$OldFolder,
   [parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl]$ParentOfNewFolder,
   [parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]$NewVC,
   [parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]$OldVC
   )
  $NewFolder = New-Folder -Location $ParentOfNewFolder -Name $OldFolder.Name -Server $NewVC
  Get-VM -NoRecursion -Location ($OldFolder|Get-VIObjectByVIView) -Server $OldVC|Select-Object Name, @{N='Folder';E={$NewFolder.id}}
  foreach ($childfolder in $OldFolder.ChildEntity|Where-Object {$_.type -eq 'Folder'})
                  {
                   Copy-VCFolderStructure -OldFolder (Get-View -Id $ChildFolder -Server $OldVC) -ParentOfNewFolder $NewFolder -NewVC $NewVC -OldVC $OldVC
                  }
}

function Get-VMTree ([System.IO.DirectoryInfo]$Directory,[Int]$Spaces = 0) {
	if ($Spaces -eq 0) {
		Write-Host $Directory.Name
		$Spaces += $Directory.Name.Length
	}
	#Write-Host $Directory.Name
	$Childs = $Directory | Get-ChildItem
	ForEach ($Child in $Childs) {
		# Indentation for current object
		for ($i=0; $i -lt $Spaces; $i++) {
			Write-Host " " -NoNewline
		}
		Write-Host -NoNewline "|---" 
			$Spaces += ("|---").length
		Write-Host $Child.Name
		#if ($Child.Gettype().Name -eq "FileInfo") {	}
		if ($Child.Gettype().Name -eq "DirectoryInfo") {
			Get-VMTree -Directory $Child -Spaces ($Spaces)
		}
	}
}

function Get-VMWithRDM ([Parameter(Mandatory=$true,ValueFromPipeline=$true)][VMware.VimAutomation.ViCore.Types.V1.inventory.VirtualMachine[]]$VM) {
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  #>
	return Get-HardDisk -DiskType "RawPhysical","RawVirtual" -VM $VM;
}

function Get-VMDetails ([Parameter(Mandatory=$true,ValueFromPipeline=$true)] [VMware.VimAutomation.ViCore.Types.V1.inventory.VirtualMachine[]]$VM) {
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
#>
	return $($vm | Select name, @{N="PortGroups";E={$_.networkadapters.networkname}}, @{N="Datastores";E={get-datastore -id $_.datastoreidlist}})
}


function Get-VMHostWWN ([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$True)]$VMObject) {
<#
  .SYNOPSIS
  This function retrieves the WWN of the hosts.
  .DESCRIPTION
  This function retrieves the WWN of the hosts.
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  
  .LINK
  www.idgar.wordpress.com
  
#>
	#Get cluster and all host HBA information and change format from Binary to hex
	$list = $VMObject | Get-VMHostHBA -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}} | Sort VMhost,Device

    #Go through each row and put : between every 2 digits
	foreach ($item in $list){
       $item.wwn = (&{for ($i=0;$i -lt $item.wwn.length;$i+=2)
                        {
                            $item.wwn.substring($i,2)   
                        }}) -join':'
    }
	return $list
}

function Get-SQLConfigString ([Parameter(Mandatory=$true)][String]$ServiceUser,[Parameter(Mandatory=$true)][String]$AdminUser,`
							  [Parameter(Mandatory=$true)][String]$ServicePassword, [Parameter(Mandatory=$true)][String]$SAPassword) {
	
	$keys = @{`
			  "INSTANCEID"="MSSQLSERVER";`
			  "ACTION"="Install";`
			  "FEATURES"="SQLENGINE,SSMS,ADV_SSMS";`
			  "HELP"="False";`
			  "INDICATEPROGRESS"="False";`
			  "X86"="False";`
			  "ENU"="True";`
			  "ERRORREPORTING"="False";`
			  "INSTALLSHAREDDIR"="C:\Program Files\Microsoft SQL Server";`
			  "INSTALLSHAREDWOWDIR"="C:\Program Files (x86)\Microsoft SQL Server";`
			  "INSTANCEDIR"="C:\Program Files\Microsoft SQL Server";`
			  "SQMREPORTING"="False";`
			  "INSTANCENAME"="MSSQLSERVER";`
			  "ASCOLLATION"="Latin1_General_CI_AS";`
			  "ASDATADIR"="Data";`
			  "ASLOGDIR"="Log";`
			  "ASBACKUPDIR"="Backup";`
			  "ASTEMPDIR"="Temp";`
			  "ASCONFIGDIR"="Config";`
			  "ASPROVIDERMSOLAP"="1";`
			  "FARMADMINPORT"="0";`
			  "SQLSVCSTARTUPTYPE"="Automatic";`
			  "FILESTREAMLEVEL"="0";`
			  "ENABLERANU"="False";`
			  "SQLCOLLATION"="SQL_Latin1_General_CP1_CI_AS";`
			  "SECURITYMODE"="SQL";`
			  "ADDCURRENTUSERASSQLADMIN"="False";`
			  "TCPENABLED"="1";`
			  "NPENABLED"="0";`
			  "BROWSERSVCSTARTUPTYPE"="Disabled";`
			  "RSSVCSTARTUPTYPE"="Automatic";`
			  "RSINSTALLMODE"="FilesOnlyMode"}

	$keys += @{"QUIET"="True"}
	
	$keys += @{"AGTSVCACCOUNT"="$ServiceUser";`
			   "ISSVCACCOUNT"="$ServiceUser";`
			   "SQLSVCACCOUNT"="$ServiceUser";`
			   "SQLSYSADMINACCOUNTS"="$AdminUser";`
			   "AGTSVCPASSWORD"="$ServicePassword";`
			   "ISSVCPASSWORD"="$ServicePassword";`
			   "SQLSVCPASSWORD"="$ServicePassword";`
			   "SAPWD"="$SAPassword"}

	$keys += @{"AGTSVCSTARTUPTYPE"="Manual";`
			   "ISSVCSTARTUPTYPE"="Automatic";`
			   "ASSVCSTARTUPTYPE"="Automatic"}
	
	
	#foreach ($sqlparam in $keys.keys) {
	#	$string += $sqlparam + "=`"" + $keys.Item($sqlparam) + "`"`n"
	#}
	
	[String]$command = ""
	foreach ($sqlparam in $keys.keys) {
		$command += "/" + $sqlparam + "=`"" + $keys.Item($sqlparam) + "`" "
	}
	$command += "/IACCEPTSQLSERVERLICENSETERMS"
	return $command
}

function New-VMSQLServer ([Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
						  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM, [Parameter(Mandatory=$true)][String]$InstallPath,`
						  [Parameter(Mandatory=$true)][String]$ServiceUser,[Parameter(Mandatory=$true)][String]$AdminUser,`
						  [Parameter(Mandatory=$true)][String]$ServicePassword, [Parameter(Mandatory=$true)][String]$SAPassword,`
						  [Parameter(Mandatory=$false)][String]$ISODSName, [Parameter(Mandatory=$false)][String]$ISOPath) {
		# /configurationfile='C:\Temp\ConfigurationFile.ini'
		#"/IACCEPTSQLSERVERLICENSETERMS /AGTSVCPASSWORD=`"$Password`" /ISSVCPASSWORD=`=$Password /SQLSVCPASSWORD`=$Password" + `
		#"/SAPWD`=$Password"
		
		#Mounting installation iso before
		if (($ISODSName -ne $null) -and ($ISOPath -ne $null)) {
			$(Get-VM -Name $VM) | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false
		}
		#Running Installation
		Invoke-VMScript -ScriptText $($InstallPath +  " " + $(Get-SQLConfigString -ServiceUser $ServiceUser -ServicePassword $ServicePassword -SAPassword $SAPassword -AdminUser $AdminUser)) -GuestCredential $GuestCredential -VM $(Get-VM -Name $VM)
}

function New-VMADDS ([Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
					 [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM,
					 [Parameter(Mandatory=$true)][String]$DomainName,
					 [String]$AdminPassword) {
	#For Windows 2012
	#Invoke-VMScript -VM $vm -ScriptText "Install-WindowsFeature -Name AD-Domain-Services" -GuestCredential $GuestCredential -ScriptType Powershell

	#For Windows 2008R2
	Invoke-VMScript -VM $vm -GuestCredential $GuestCredential -ScriptType Bat -ScriptText "dcpromo /unattend /InstallDns:yes /dnsOnNetwork:yes /replicaOrNewDomain:domain /newDomain:forest /newDomainDnsName:$DomainName /DomainNetbiosName:contoso /databasePath:`"e:\Windows\ntds`" /logPath:`"e:\Windows\ntdslogs`" /sysvolpath:`"e:\Windows\sysvol`" /safeModeAdminPassword:$AdminPassword /forestLevel:2 /domainLevel:2 /rebootOnCompletion:yes"
	
}

function New-VMPostgresSQL ([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM,`
							[Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
							[Parameter(Mandatory=$true)][String]$AdminPassword) {
	
	$InstScript = `
	"echo `"Installing PostgreSQL`"" + "sudo apt-get update &> /dev/null
	sudo apt-get install postgresql postgresql-contrib -y &> /dev/null
	echo 'Installing GUI admin tool - pgadmin III'
	sudo apt-get install pgadmin3 &> /dev/null
	echo `"Creating user and database for user $USER`"
	sudo -i -u postgres bash -c `"createuser --superuser $USER  && createdb $USER`"
	echo -n `"Enter $USER password: `" && read -s password
	psql -c `"alter user $USER with password $password` "
	
	Invoke-VMScript -VM $vm -GuestCredential $GuestCredential -ScriptType Bash -ScriptText $InstScript
}

function Get-SnapshotDays ([Parameter(Mandatory=$true,ValueFromPipeline=$true)][VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]$VM) {
	$VM | Get-Snapshot | select created, name,vm,@{N="days";E={ (new-timespan -start ($_.created) -End (get-date)).days  }}
}

#function Get-SnapshotDays ([Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$false)][VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]$VM) {
#	$VM
#}