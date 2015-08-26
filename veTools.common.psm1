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

function Convert-HashToMSI ([Parameter(Mandatory=$true)][System.Collections.Hashtable]$Params) {
	[String]$command = ""
	foreach ($currparam in $Params.keys) {
		$command += "/" + $currparam + "=`"" + $Params.Item($currparam) + "`" "
	}
	return $command
}

function Convert-HashToMSI2 ([Parameter(Mandatory=$true)][System.Collections.Hashtable]$Params) {
	[String]$command = ""
	foreach ($currparam in $Params.keys) {
		#Write-Host "current parameter: $currparam"
		$command += $currparam + '="' + $Params.Item($currparam) + '" '
	}
	return $command
}

function Convert-HashToMSIEXE ([Parameter(Mandatory=$true)][System.Collections.Hashtable]$Params) {
	[String]$command = ""
	foreach ($currparam in $Params.keys) {
		$command += $currparam + '=\"' + $Params.Item($currparam) + '\" '
	}
	return $command
}

function Get-STRFromSecureString ([Parameter(Mandatory=$true)] [System.Security.SecureString]$Password) {
	#First convert to binary then to string
	return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(`
		[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
}

function Test-IsAdmin {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Test-IsIpExists ([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$IP) {
	process {
		return (Test-Connection -ComputerName $IP -Count 1 -Quiet)
	}
}

function Test-IsVcConnected {
	if ($DefaultViServer -eq $null) {
		return $false
	}
	else {
		return $true
	}
}

function Print-dashes ([int]$Count) {
	for ($i=0; $i -lt $count; $i++) {
		Write-Host "-" -NoNewline
	}
	Write-Host
}

function Test-IsNumeric ([String]$Object) {
	return ($Object -match "^[0-9]*$")
}

function Print-Menu ([String]$ObjectType,[System.Array]$ObjectList,[String]$PropertyName) {
	$title = "Choose $($ObjectType)"
	Write-Host $title
	Print-Dashes -Count ($title.length)		
	
	for ($i=0; $i -lt ($ObjectList.length); $i++) {
		Write-Host -NoNewline "$i. "
		Write-Host "$($ObjectList[$i].$PropertyName)"
	}
	$ValidInput = $false
	while ($ValidInput -eq $false) {
		$ObjectSelect = Read-Host -Prompt "Enter your selection"
		if( ((Test-IsNumeric -Object $ObjectSelect) -eq $true) -and `
			([Int]$ObjectSelect -le ($ObjectList.length)) ) {
			$ReturnObject = $ObjectList[$ObjectSelect].$PropertyName
			$ValidInput = $true
		}
	}
	Write-Host "Your selection is '$ReturnObject'" -ForegroundColor Yellow
	Write-Host
	return $ReturnObject
}

function Test-IsAdmin {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}