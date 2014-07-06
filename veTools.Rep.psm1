function Set-powerOffDetails ([Parameter(Mandatory=$true)] [System.Security.SecureString]$Password) {
	
	$SqlConnection = $global:DefaultSQLServer

	#Building the command
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection

	$lastpower = Get-CiPowerOffDetails  -OrgName "ENT_RnD" 
	$lastpower = $lastpower | Sort-Object -Unique -Property vmuuid

	foreach ($currtask in $lastpower) {
		#Insert new VM to the table.
		$SqlCmd.CommandText = "INSERT INTO dbo.PowerOffDetails VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}')" -f $currtask.Owner,$currtask.VMName,$currtask.VMuuid,`
			$currtask.vAppName,$currtask.vAppuuid,$currtask.OrgName,([datetime]::Parse($currtask.Date)).ToString(),$currtask.LastLogin,$currtask.actionExecuter
		#Trying to insert new record.
		try {
			$SqlCmd.ExecuteNonQuery()
		}
		#Exception following unique constraint
		catch [Exception] {
				#Update existing VM in the table.
				$SqlCmd.CommandText = "UPDATE dbo.PowerOffDetails " + `
									  "SET Owner='{1}',VMName='{2}',vAppName='{3}',vAppuuid='{4}',OrgName='{5}',Date='{6}',actionExecuter='{7}' " + `
									  "WHERE vmuuid = '{0}';" -f $currtask.VMuuid,$currtask.Owner,$currtask.VMName,$currtask.vAppName,$currtask.vAppuuid,$currtask.OrgName,([datetime]::Parse($currtask.Date)).ToString(),$currtask.LastLogin,$currtask.actionExecuter
				$SqlCmd.ExecuteNonQuery()
		}
	}
	#Adapter to execute query
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlCmd.CommandText = "select * from dbo.poweroffdetails"
	$SqlAdapter.SelectCommand = $SqlCmd
	 
	$DataSet = New-Object System.Data.DataSet
	 
	$SqlAdapter.Fill($DataSet)
	 
	$DataSet.Tables | ft
	$SqlConnection.Close()
}