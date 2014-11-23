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
function Set-powerOffDetails ([Parameter(Mandatory=$false)]$SqlConnection = $global:DefaultSQLServer,[Parameter(Mandatory=$true)][String]$Orgname) {

	#Building the command
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection

	$lastpower = Get-CiPowerOffDetails  -OrgName $Orgname
	$lastpower = $lastpower | Sort-Object -Unique -Property @{Expression="vmuuid"},@{Expression="Date";Descending=$false}

	foreach ($currtask in $lastpower) {
		#Insert new VM to the table.
		$SqlCmd.CommandText = "INSERT INTO dbo.PowerOffDetails (owner,vmname,vmuuid,vappname,vappuuid,orgname,date,lastlogin,actionexecuter) VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}')" -f $currtask.Owner,$currtask.VMName,$currtask.VMuuid,`
			$currtask.vAppName,$currtask.vAppuuid,$currtask.OrgName,([datetime]::Parse($currtask.Date)).ToString(),$currtask.LastLogin,$currtask.actionExecuter
		#Trying to insert new record.
		try {
			$result = $SqlCmd.ExecuteNonQuery()
			if ($result -eq 1) {
				Write-Host "New record has inserted"
			}
		}
		#Exception following unique constraint
		catch [Exception] {
				#Update existing VM in the table.
				$SqlCmd.CommandText = "UPDATE dbo.PowerOffDetails " + `
									  "SET Owner='{0}',VMName='{1}',vAppName='{2}',vAppuuid='{3}',OrgName='{4}',Date='{5}',LastLogin='{6}',actionExecuter='{7}' " `
									  -f $currtask.Owner,$currtask.VMName,$currtask.vAppName,$currtask.vAppuuid,$currtask.OrgName,([datetime]::Parse($currtask.Date)).ToString(),$currtask.LastLogin,$currtask.actionExecuter + `
									  "WHERE vmuuid = '{0}';" -f $currtask.VMuuid
				$result = $SqlCmd.ExecuteNonQuery()
				if ($result -eq 1) {
					Write-Host "a record has updated "
				}
		}
	}
	#Adapter to execute query
	#$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	#$SqlCmd.CommandText = "select * from dbo.poweroffdetails"
	#$SqlAdapter.SelectCommand = $SqlCmd
	 
	#$DataSet = New-Object System.Data.DataSet
	 
	#$SqlAdapter.Fill($DataSet)
	 
	#$DataSet.Tables | ft
}