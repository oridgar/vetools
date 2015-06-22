param([Parameter(ValueFromPipeline=$true,Mandatory=$true)]$VMHost)
process {
	$vmh = Get-VMHost $VMHost
	If ($vmh.State -ne "Connected") {
	  Write-Output "Host $($vmh) state is not connected, skipping."
	  }
	Else {
	  Get-View $vmh.ID | `
	  % { $esxname = $_.Name; Get-View $_.ConfigManager.NetworkSystem} | `
	  % { foreach ($physnic in $_.NetworkInfo.Pnic) {
	    $pnicInfo = $_.QueryNetworkHint($physnic.Device)
	    foreach( $hint in $pnicInfo ){
	      # Write-Host $esxname $physnic.Device
	      if ( $hint.ConnectedSwitchPort ) {
	        $hint.ConnectedSwitchPort | select @{n="VMHost";e={$esxname}},@{n="VMNic";e={$physnic.Device}},DevId,Address,PortId,HardwarePlatform
	        }
	      else {
	        "" | select @{n="VMHost";e={$esxname}},@{n="VMNic";e={$physnic.Device}},@{n="DevId";e={}},@{n="Address";e={}},@{n="PortId";e={}},@{n="HardwarePlatform";e={HardwarePlatform}}
			#Write-Host "No CDP information available."
	        }
	      }
	    }
	  }
	}
}