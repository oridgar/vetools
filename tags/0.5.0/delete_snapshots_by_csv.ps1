Param([Parameter(Mandatory=$true)] $Excel_Name)

$SnapshotArr = @()

$Snapshots_list = Import-Csv $Excel_Name

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