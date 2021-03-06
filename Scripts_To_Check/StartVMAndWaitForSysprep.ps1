function StartVMAndWaitForSysprep
(
	[Parameter(Mandatory=$True)]
	[Vmware.VIMAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$vmRef
)
{
	$vm = Start-VM $vmRef -Confirm:$False -ErrorAction:Stop
 
	# wait until VM has started
	Write-Host "Waiting for VM to start ..."
	while ($True)
	{
		$vmEvents = Get-VIEvent -Entity $vm
 
		$startedEvent = $vmEvents | Where { $_.GetType().Name -eq "VMStartingEvent" }
 
		if ($startedEvent) 
		{
			break
		}
		else
		{
			Start-Sleep -Seconds 2	
		}	
	}
 
	# wait until customization process has started	
	Write-Host "Waiting for Customization to start ..."
	while($True)
	{
		$vmEvents = Get-VIEvent -Entity $vm 
		$startedEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationStartedEvent" }
 
		if ($startedEvent)
		{
			break	
		}
		else 	
		{
			Start-Sleep -Seconds 2
		}
	}
 
	# wait until customization process has completed or failed
	Write-Host "Waiting for customization ..."
	while ($True)
	{
		$vmEvents = Get-VIEvent -Entity $vm
		$succeedEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationSucceeded" }
		$failEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationFailed" }
 
		if ($failEvent)
		{
			Write-Host "Customization failed!"
			return $False
		}
 
		if($succeedEvent)
		{
			Write-Host "Customization succeeded!"
			return $True
		}
 
		Start-Sleep -Seconds 2			
	}
}