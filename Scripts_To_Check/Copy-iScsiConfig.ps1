param([Parameter(Mandatory=$true)]$SourceHost,
	  [Parameter(Mandatory=$true)]$TargetHost)

$ErrorActionPreference = "Stop"

#Dependencies check

$Result = @()
$RejectList = @()
try {
	#$session = $null
	
	Write-Host "Getting hosts..." -ForegroundColor Yellow -NoNewline
	$SourceHostObj = Get-VMHost -Name $SourceHost
	$TargetHostObj = Get-VMhost -Name $TargetHost
	Write-Status $?
	
	Write-host "Enable the software ISCSI adapter if not already enabled..." -NoNewline
	$VMHostStorage = Get-VMHostStorage -VMHost $TargetHostObj | Set-VMHostStorage -SoftwareIScsiEnabled $True            
	Write-Status $?
	
	#sleep while iSCSI starts up
	Start-Sleep -Seconds 10

	Write-Host "Getting iSCSI software adapters..." -NoNewline
	$VMSourceHostHba = Get-VMHostHba -VMHost $SourceHostObj -Type IScsi
	$VMTargetHostHba = Get-VMHostHba -VMHost $TargetHostObj -Type IScsi
	Write-Status $?

	Write-Host "Getting all targets on source iSCSI adapter..." -NoNewline
	$SourceHostTargets = $VMSourceHostHba | Get-IScsiHbaTarget
	Write-Status $?

	$TargetHostTargets = @()
	foreach ($currTarget in $SourceHostTargets) {
		Write-Host "Adding target $($currTarget.Address)..." -NoNewline
		$TargetHostTargets += New-IScsiHbaTarget -Address ($currTarget.Address) -Port ($currTarget.Port) -Type ($currTarget.Type) -IScsiHba $VMTargetHostHba -ErrorAction SilentlyContinue
		Write-Status $?
	}
	$TargetHostTargets
	
	Write-Host "Rescan target host..." -NoNewline
	$TargetHostObj | Get-VMHostStorage -RescanAllHba
	Write-Status $?
}
catch {
	Write-Host "Issues with ESX '" $($currEsx.Name) "'" -ForegroundColor Red
	#$RejectList += $($currEsx.Name)
}
finally {
}

#$Result | Export-Csv -NoTypeInformation $OutListFile
#$RejectList | Export-Csv -NoTypeInformation $OutRejectFile
#return $Result