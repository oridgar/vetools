IParam([Parameter(Mandatory=$true)] [string]$ClusterName)
#	[Parameter(Mandatory=$true)] [string]$vds_name,`
#	[Parameter(Mandatory=$true)] [string]$vss_name)

# --------------------
# Variable Declaration
# --------------------

$pnic_array = @()
$pg_array = @()

# VDS to migrate from
#$vds_name = "VDS-01"

# VSS to migrate to
#$vss_name = "vSwitch0"

# ESXi hosts to migrate from VSS->VDS
#$vmhost_array = @("vesxi55-1.primp-industries.com","vesxi55-2.primp-industries.com","vesxi55-3.primp-industries.com")

# ------------
# Code Section
# ------------

Write-Host "Gathering data..."
Write-Host "Getting all hosts in cluster $ClusterName..."
$vmhost_array = (Get-Cluster -Name $ClusterName | Get-VMHost | Sort-Object)
Write-Host "Getting all distributed switches in cluster $ClusterName..."
$vds_array = $vmhost_array | Get-VDSwitch


foreach ($curr_vds in $vds_array) {
	#Pause
	Write-Host "Working on distributed switch $curr_vds..." -ForegroundColor Blue
	Write-Host
	Write-Host "Getting all port groups of current distributed switch".
	$vds_portgroups = ($curr_vds | Get-VDPortgroup | Where-Object {$_.IsUplink -eq $false})
	
	Write-Host "Creating objects in each host in cluster $ClusterName..."
	foreach ($vmhost in $vmhost_array)
	{
		# ------------------------------------------------
		# Creating of standard switch & underlined objects
		# ------------------------------------------------
		
		Write-Host "Current host: $vmhost" -ForegroundColor Cyan
		Write-Host
		Write-Host "Creating standard switch $curr_vds"
		# Pause
		# Check if the standard switch exists
		$curr_vss = ($vmhost | Get-VirtualSwitch -Name $curr_vds -Standard) 2> $null
		if ($curr_vss -eq $null) {
			# Creating correlated virtual standard switches on all hosts. 
			$curr_vss = ($vmhost | New-VirtualSwitch -Name $curr_vds)
		}
		
		#TODO - check VDS global MTU setting. if its not 1500 you should configure the same
		#in VSS
		#if ($curr_vds.mtu -ne 1500) {
			#curr_vss | set-Virtualswitch -mtu [something] -Confirm:$false
		#}
		
		#------------------------------------
		#Getting physical nics of current DVS
		#------------------------------------
		#Write-Host "Getting all physical NICs to migrate to VSS..."
		# Array of pNICs to migrate to VSS
		#$pnic_array = $vmhost | Get-VMHostNetworkAdapter | Where-Object {$_.name -like "vmnic*"}
		
		#------------------------------------------
		#Migrate all but one vmnics from DVS to VSS
		#------------------------------------------
		# This code connect nics to standard switch
				
		#TODO - Disconnect the vmnic before
		# $curr_vss | set-virtualswitch -nic "somenic"
		
		# Create destination portgroups
        Write-Host "Creating port groups"
		foreach ($curr_portgroup in $vds_portgroups)
		{
			Write-Host "Creating port group" $curr_portgroup.name
			# Pause
			if ($curr_portgroup.VlanConfiguration -ne $null) {
				$curr_vss_pg = New-VirtualPortGroup -VirtualSwitch $curr_vss -Name ($curr_portgroup.name) -VLanId ($curr_portgroup.VlanConfiguration.VlanId)
				$pg_array += $curr_vss_pg
			}
			else {
				$curr_vss_pg = New-VirtualPortGroup -VirtualSwitch $curr_vss -Name ($curr_portgroup.name)
				$pg_array += $curr_vss_pg
			}

			#--------------------------------------
			#Migrate VMKernel ports from DVS to VSS 
			#except the one which binded to the vmnic 
			#that is still connected to DVS
			#--------------------------------------
			#Write-Host "Getting all virtual adapters (vmk) to migrate to VSS..."
			#Array of virtual adapters to migrate to VSS
			#OLD CODE!!!
			####$vmk_array = $vmhost | Get-VMHostNetworkAdapter | Where-Object {$_.name -like "vmk*"}
			
			
			#TODO - check if we need to create port group for vmkernel in the standard switch before migrating vmkernel			
			
			#$vmhost_vmk_arr =  $curr_vds | Get-VMHostNetworkAdapter | Where-Object {$_.VMHostId -eq $($vmhost.id) -and $_.name -like "vmk*"}
			#TODO - need to check if there are bindings of vmk and vmnic
			#foreach ($curr_vmk in $vmhost_vmk_arr) {
				#TODO - must find how to make it move to standard switch.
				#$curr_vmk | Set-VMHostNetworkAdapter -PortGroup $($curr_vss_pg.name)
			#}

			#---------------------------
			#Migrate VMs from DVS to VSS
			#---------------------------
			#$vmhost | Get-VM | Get-NetworkAdapter | Where-Object {$_.NetworkName -eq ($curr_pg.name) } | Set-NetworkAdapter -NetworkName ($curr_pg.name) -Confirm:$false
		}
		
		#----------------------------------
		#Migrate last vmnic from DVS to VSS
		#----------------------------------
		#$last_vmnic = $curr_vds | Get-VMHostNetworkAdapter | Where-Object {$_.VMHostId -eq $($vmhost.id) -and $_.name -like "vmnic*"}
		# $curr_vss | set-virtualswitch -nic $(@("somenic") + [current nics])
		
		#-------------------------------------------------
		#Migrate binded vmk for last vmnic from DVS to VSS
		#-------------------------------------------------
		#Getting last vmkernel port from current VDS
		#$last_vmk = $curr_vds | Get-VMHostNetworkAdapter | Where-Object {$_.VMHostId -eq $($vmhost.id) -and $_.name -like "vmk*"}
		
		#migrating last vmkernel port to VSS
		#$curr_vmk | Set-VMHostNetworkAdapter -PortGroup $($curr_vss_pg.name)
	}
}

# Migrating cluster host by host
#foreach ($vmhost in $vmhost_array) {
#        Write-Host "`nProcessing" $vmhost
#
##        # Array of pNICs to migrate to VSS
##		$pnic_array = $vmhost | Get-VMHostNetworkAdapter | Where-Object {$_.name -like "vmnic*"}
#
#        # vSwitch to migrate to
#		#$vss = ($vmhost | New-VirtualSwitch -Name $vss_name)
#		#$vss = $vmhost | Get-VirtualSwitch -Name $vss_name
#
##        # Create destination portgroups
##        foreach ($curr_portgroup in $vds_portgroups)
##		{
##			$pg_array += New-VirtualPortGroup -VirtualSwitch $vss -Name ($curr_portgroup.name)
##		}
#		
##		# Array of virtual adapters to migrate to VSS
##		$vmk_array = $vmhost | Get-VMHostNetworkAdapter | Where-Object {$_.name -like "vmk*"}
#		
#		# ---------------------------------------------------------
#		# Moving objects from distributed switch to standard switch
#		# ---------------------------------------------------------
#		
#		# Moving first physical adapter to vSS
#		Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vss -VMHostPhysicalNic $pnic_array[0] -Confirm:$false
#			
#		# Migrating virtual adapters (vmkernel port groups)
#		Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vss -VMHostVirtualNic $vmk_array -VirtualNicPortgroup $pg_array
#
#		# Migrating virtual machines
#		foreach ($curr_pg in $pg_array)
#		{
#			$vmhost | Get-VM | Get-NetworkAdapter | Where-Object {$_.NetworkName -eq ($curr_pg.name) } | Set-NetworkAdapter -NetworkName ($curr_pg.name) -Confirm:$false
#		}
#		
#		# Moving rest of physical adapters to vSS
#		for ($i = 1; $i -lt ($pnic_array.length); $i++)
#		{
#			Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vss -VMHostPhysicalNic $pnic_array[$i] -Confirm:$false
#		}
#		
#        # Perform the migration
##        Write-Host "Migrating from" $vds_name "to" $vss_name"`n"
##        Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $vss -VMHostPhysicalNic $pnic_array -VMHostVirtualNic $vmk_array -VirtualNicPortgroup $pg_array  -Confirm:$false
#		Write-Host "`nRemoving" $vmhost_array "from" $vds_name
#		$vds | Remove-VDSwitchVMHost -VMHost $vmhost_array -Confirm:$false
#}