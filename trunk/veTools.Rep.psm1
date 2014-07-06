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
function Set-powerOffDetails ([Parameter(Mandatory=$false)]$SqlConnection = $global:DefaultSQLServer) {
	
	

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