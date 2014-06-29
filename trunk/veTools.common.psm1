function Connect-SQLServer([string]$IP,[string]$InstanceName,[string]$Port,[string]$UserId,[string]$Password,[string]$DBName) {
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Data Source=$IP\$InstanceName,$Port;User Id=$UserId;Password=$Password;Database=$DBName;"
	
	#connect to sql server and save the connection.
	$SqlConnection.Open()
	if ($?) {
		$global:DefaultSQLServer= $SqlConnection
	}
	return $global:DefaultSQLServer
}

function Disconnect-SQLServer($SQLConenction=$global:DefaultSQLServer) {
	$SqlConnection.Close()
}

function Get-SQLQuery($SqlConnection=$global:DefaultSQLServer,$Query) {
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

function Set-SQLQuery($SqlConnection=$global:DefaultSQLServer,$Query) {
	#Building the command
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	
	$SqlCmd.CommandText = $Query
	return $SqlCmd.ExecuteNonQuery()
}