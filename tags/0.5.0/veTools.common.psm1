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


﻿function Connect-SQLServer([string]$IP,[string]$InstanceName,[string]$Port,[string]$UserId,[string]$Password,[string]$DBName) {
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
