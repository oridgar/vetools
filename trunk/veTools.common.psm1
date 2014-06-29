function Connect-SQLServer([string]$IP,[string]$InstanceName,[string]$Port,[string]$UserId,[string]$Password,[string]$DBName) {
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Data Source=$IP\\$InstanceName,$Port;User Id=$UserId;Password=$Password;Database=$DBName;"
	 
	return $SqlConnection.Open()
}

function Disconnect-SQLServer($SQLConenction) {
	$SqlConnection.Close()
}

function Get-SQLQuery($SqlConnection,$Query) {
	#Building the command
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	$SqlCmd.CommandText = $Query
		
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
 
	$DataSet = New-Object System.Data.DataSet
 	$SqlAdapter.Fill($DataSet)
	
	return $DataSet
}

function Set-SQLQuery() {
	#Building the command
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	
	$SqlCmd.CommandText = $Query
	return $SqlCmd.ExecuteNonQuery()
}