param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][VMware.VimAutomation.ViCore.Impl.V1.inventory.VirtualMachineImpl[]]$vm,[parameter(mandatory=$true)]$dummyPgName,[switch]$allStates)
process {
	#$vm = Get-VM $VmName
	$nics = $vm | Get-NetworkAdapter
	Write-Host
	Write-Host ("Working on: " + ($vm.name)) -ForegroundColor Yellow

	foreach($currnic in $nics) {
		#getting current dvswitch
		#getting current port group
		$currVds = $currnic.ExtensionData.Backing.Port.SwitchUuid
		$currPg = $currnic.ExtensionData.Backing.Port.PortgroupKey
		
		#Getting vds managed object
		$currVdsMo = Get-View -ViewType VmwareDistributedVirtualSwitch -Filter @{"Uuid"=$currVds}
		
		#Getting PowerCLI Objects
		$currVdsObj = Get-VDSwitch -Id $currvdsMo.MoRef
		$currPgObj = $currVdsObj | Get-VDPortgroup | Where-Object {$_.key -eq $currPg}
		$dummyPgObj = $currVdsObj | Get-VDPortgroup -Name $dummyPgName
		
		Write-Host
		Write-Host ("Current NIC: " + ($currnic.Name)) -ForegroundColor Yellow
		
		if (($allStates -eq $true) -or ($currnic.ConnectionState.Connected -eq $false -and $vm.PowerState -eq "PoweredOn")) {
			Write-Host ("Current vDS: " + ($currVdsObj.Name))
			Write-Host ("Current Port Group: " + ($currPgObj.Name))
			Write-Host ("Dummy Port Group: " + ($dummyPgObj.Name))
		
			#pause
			Write-host "Moving to dummy port group"
			Set-NetworkAdapter -NetworkAdapter $currnic -Portgroup $dummyPgObj -Confirm:$false | Out-Null
			
			Write-host "Moving back to original port group"
			Set-NetworkAdapter -NetworkAdapter $currnic -Portgroup $currPgObj -Confirm:$false | Out-Null
			
			Write-host "Enabling NIC"
			Set-NetworkAdapter -NetworkAdapter $currnic -StartConnected:$true -Connected:$true -Confirm:$false | Out-Null
		}
		else {
			Write-Host "Already Connected"
		}
	}
}