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

function New-DB([Parameter(Mandatory=$true)][String]$dbname,[Parameter(Mandatory=$true)]$servername,[Parameter(Mandatory=$false)]$instanceName,[Parameter(Mandatory=$false)][Int]$dataFileSizeMB,[Parameter(Mandatory=$false)][Int]$logFileSizeMB) {
	#createdb.ps1
	#Creates a new database using our specifications

	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')  | out-null

	#$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') 'MyServer/MyInstance'
	$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') $servername

	#The next thing we'll do is set a string variable to the name of the database. This value can also be supplied as an argument to the script if you want. Then we'll instantiate the database object and add filegroups for PRIMARY (required for SQL Server), and another filegroup I call AppFG for the application data. I've found that I improve performance and recoverability by putting only the database metadata in the PRIMARY filegroup, setting its size to 5MB without expansion, then setting the AppFG (application filegroup) to be the default filegroup.

	# Instantiate the database object and add the filegroups
	$db = new-object ('Microsoft.SqlServer.Management.Smo.Database') ($s, $dbname)
	$sysfg = new-object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($db, 'PRIMARY')
	$db.FileGroups.Add($sysfg)
	$appfg = new-object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($db, 'AppFG')
	$db.FileGroups.Add($appfg)

	#Once the filegroups have been created, we can create the files for the database. First we create the file for the database metadata. I've set the size to be 5MB with no growth. To create the database the PRIMARY filegroup has to be set to be the default, so we'll set that here as well.

	# Create the file for the system tables
	$syslogname = $dbname + '_SysData'
	$dbdsysfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($sysfg, $syslogname)
	$sysfg.Files.Add($dbdsysfile)
	$dbdsysfile.FileName = $s.Information.MasterDBPath + '\' + $syslogname + '.mdf'
	$dbdsysfile.Size = [double]($dataFileSizeMB * 1024.0)
	$dbdsysfile.GrowthType = 'None'
	$dbdsysfile.IsPrimaryFile = 'True'

	# Next we'll create the file to hold the application tables. Normally 25MB works for my databases, so I've set that in the Size parameter, and I use a growth parameter of 25%, because 10% is too small an increment when growth is required, in my opinion. I've also set a maximum size for this file of 100MB. I have to watch this to make sure we don't run out of space, but this is rarely a problem in my environment, and this max helps prevent me from running out of physical disk. (Note that sizes are specified in KB units, so I "do the math" in the script so it's easier to read.)

	# Create the file for the Application tables
	$applogname = $dbname + '_AppData'
	$dbdappfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($appfg, $applogname)
	$appfg.Files.Add($dbdappfile)
	$dbdappfile.FileName = $s.Information.MasterDBPath + '\' + $applogname + '.ndf'
	$dbdappfile.Size = [double](25.0 * 1024.0)
	$dbdappfile.GrowthType = 'Percent'
	$dbdappfile.Growth = 25.0
	$dbdappfile.MaxSize = [double](100.0 * 1024.0)

	#Now I can create the file for the transaction log. I set this to an initial size of 10MB with 25% growth.

	# Create the file for the log
	$loglogname = $dbname + '_Log'
	$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($db, $loglogname)
	$db.LogFiles.Add($dblfile)
	$dblfile.FileName = $s.Information.MasterDBLogPath + '\' + $loglogname + '.ldf'
	$dblfile.Size = [double]($logFileSizeMB * 1024.0)
	$dblfile.GrowthType = 'Percent'
	$dblfile.Growth = 10.0

	#We can create the database now, and once it's been created we can grab the AppFG filegroup, set it's default property to True, alter the filegroup and alter the database. Now it's ready for loading the tables and other objects necessary for the application to work properly.

	# Create the database
	$db.Create()

	# Set the default filegroup to AppFG
	$appfg = $db.FileGroups['AppFG']
	$appfg.IsDefault = $true
	$appfg.Alter()
	$db.Alter()
}