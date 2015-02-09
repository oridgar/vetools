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

function Get-SQLConfigString ([Parameter(Mandatory=$true)][String]$ServiceUser,[Parameter(Mandatory=$true)][String]$AdminUser,`
							  [Parameter(Mandatory=$false)][String]$ServicePassword="", [Parameter(Mandatory=$true)][String]$SAPassword) {
	
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  
  .LINK 
  https://code.google.com/p/vetools/wiki/Main
#>
	$keys = @{`
			  "INSTANCEID"="MSSQLSERVER";`
			  "ACTION"="Install";`
			  "FEATURES"="SQLENGINE,SSMS,ADV_SSMS";`
			  "HELP"="False";`
			  "INDICATEPROGRESS"="False";`
			  "X86"="False";`
			  "ENU"="True";`
			  "ERRORREPORTING"="False";`
			  "INSTALLSHAREDDIR"="C:\Program Files\Microsoft SQL Server";`
			  "INSTALLSHAREDWOWDIR"="C:\Program Files (x86)\Microsoft SQL Server";`
			  "INSTANCEDIR"="C:\Program Files\Microsoft SQL Server";`
			  "SQMREPORTING"="False";`
			  "INSTANCENAME"="MSSQLSERVER";`
			  "ASCOLLATION"="Latin1_General_CI_AS";`
			  "ASDATADIR"="Data";`
			  "ASLOGDIR"="Log";`
			  "ASBACKUPDIR"="Backup";`
			  "ASTEMPDIR"="Temp";`
			  "ASCONFIGDIR"="Config";`
			  "ASPROVIDERMSOLAP"="1";`
			  "SQLSVCSTARTUPTYPE"="Automatic";`
			  "FILESTREAMLEVEL"="0";`
			  "ENABLERANU"="False";`
			  "SQLCOLLATION"="SQL_Latin1_General_CP1_CI_AS";`
			  "SECURITYMODE"="SQL";`
			  "ADDCURRENTUSERASSQLADMIN"="False";`
			  "TCPENABLED"="1";`
			  "NPENABLED"="0";`
			  "BROWSERSVCSTARTUPTYPE"="Disabled";`
			  "RSSVCSTARTUPTYPE"="Automatic";`
			  "RSINSTALLMODE"="FilesOnlyMode"}

	$keys += @{"QUIET"="True"}
	
	$keys += @{"AGTSVCACCOUNT"="$ServiceUser";`
			   "ISSVCACCOUNT"="$ServiceUser";`
			   "SQLSVCACCOUNT"="$ServiceUser";`
			   "SQLSYSADMINACCOUNTS"="$AdminUser";`
			   "SAPWD"="$SAPassword"}
			   
	if ($ServicePassword -ne "") {
		$keys += @{"AGTSVCPASSWORD"="$ServicePassword";`
				   "ISSVCPASSWORD"="$ServicePassword";`
				   "SQLSVCPASSWORD"="$ServicePassword"}
	}

	$keys += @{"AGTSVCSTARTUPTYPE"="Manual";`
			   "ISSVCSTARTUPTYPE"="Automatic";`
			   "ASSVCSTARTUPTYPE"="Automatic"}

	#"FARMADMINPORT"="0";`
	
	
	#foreach ($sqlparam in $keys.keys) {
	#	$string += $sqlparam + "=`"" + $keys.Item($sqlparam) + "`"`n"
	#}
	
	[String]$command = ""
	foreach ($sqlparam in $keys.keys) {
		$command += "/" + $sqlparam + "=`"" + $keys.Item($sqlparam) + "`" "
	}
	$command += "/IACCEPTSQLSERVERLICENSETERMS"
	return $command
}

function New-VMSQLServer ([Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
						  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM, [Parameter(Mandatory=$true)][String]$InstallPath,`
						  [Parameter(Mandatory=$true)][String]$ServiceUser,[Parameter(Mandatory=$true)][String]$AdminUser,`
						  [Parameter(Mandatory=$false)][String]$ServicePassword, [Parameter(Mandatory=$true)][String]$SAPassword,`
						  [Parameter(Mandatory=$false)][String]$ISODSName, [Parameter(Mandatory=$false)][String]$ISOPath) {
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  
  .LINK 
  https://code.google.com/p/vetools/wiki/Main
#>
		process {
			# /configurationfile='C:\Temp\ConfigurationFile.ini'
			#"/IACCEPTSQLSERVERLICENSETERMS /AGTSVCPASSWORD=`"$Password`" /ISSVCPASSWORD=`=$Password /SQLSVCPASSWORD`=$Password" + `
			#"/SAPWD`=$Password"
					
			#Mounting installation iso before
			if (($ISODSName -ne $null) -and ($ISOPath -ne $null)) {
				$(Get-VM -Name $VM) | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false
			}
			
			#Installing prerequisites
			#Invoke-VMScript -ScriptText "Install-WindowsFeature Net-Framework-Core -Source D:\sources\sxs"  -GuestCredential $GuestCredential -VM $(Get-VM -Name $VM) -ScriptType Powershell
			
			#Running Installation
			Invoke-VMScript -ScriptText $($InstallPath +  " " + $(Get-SQLConfigString -ServiceUser $ServiceUser -ServicePassword $ServicePassword -SAPassword $SAPassword -AdminUser $AdminUser)) -GuestCredential $GuestCredential -VM $(Get-VM -Name $VM)
		}
}

function New-VMADDS ([Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
					 [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM,
					 [Parameter(Mandatory=$true)][String]$DomainName,
					 [String]$AdminPassword) {
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  
  .LINK 
  https://code.google.com/p/vetools/wiki/Main
#>
	process {
		#For Windows 2012
		#Invoke-VMScript -VM $vm -ScriptText "Install-WindowsFeature -Name AD-Domain-Services" -GuestCredential $GuestCredential -ScriptType Powershell

		#For Windows 2008R2
		Invoke-VMScript -VM $vm -GuestCredential $GuestCredential -ScriptType Bat -ScriptText "dcpromo /unattend /InstallDns:yes /dnsOnNetwork:yes /replicaOrNewDomain:domain /newDomain:forest /newDomainDnsName:$DomainName /DomainNetbiosName:contoso /databasePath:`"e:\Windows\ntds`" /logPath:`"e:\Windows\ntdslogs`" /sysvolpath:`"e:\Windows\sysvol`" /safeModeAdminPassword:$AdminPassword /forestLevel:2 /domainLevel:2 /rebootOnCompletion:yes"
	}
}

function New-VMPostgresSQL ([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM,`
							[Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
							[Parameter(Mandatory=$true)][String]$AdminPassword) {
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  
  .LINK 
  https://code.google.com/p/vetools/wiki/Main
#>
	begin {
		$InstScript = `
		"echo `"Installing PostgreSQL`"" + "sudo apt-get update &> /dev/null
		sudo apt-get install postgresql postgresql-contrib -y &> /dev/null
		echo 'Installing GUI admin tool - pgadmin III'
		sudo apt-get install pgadmin3 &> /dev/null
		echo `"Creating user and database for user $USER`"
		sudo -i -u postgres bash -c `"createuser --superuser $USER  && createdb $USER`"
		echo -n `"Enter $USER password: `" && read -s password
		psql -c `"alter user $USER with password $password` "
	}
	process {
		Invoke-VMScript -VM $vm -GuestCredential $GuestCredential -ScriptType Bash -ScriptText $InstScript
	}
}

function New-VMvCenter ([Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential,`
						  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VMname, [Parameter(Mandatory=$true)][String]$DriveLetter,`
						  [Parameter(Mandatory=$true)][String]$SSOPassword,`
						  [Parameter(Mandatory=$false)][String]$ISODSName, [Parameter(Mandatory=$false)][String]$ISOPath) {
<#
  .SYNOPSIS
  
  .DESCRIPTION
  
  .EXAMPLE
  
  .EXAMPLE
  
  .PARAMETER
  
  .LINK 
  https://code.google.com/p/vetools/wiki/Main
#>
	begin {
	}
	process {
		$VM = $(Get-VM -Name $VMname)
		
		$VM_Ip = $VM
		
		#Mounting installation iso before
		Write-Host "Mounting CDROM" -ForegroundColor Blue
		if (($ISODSName -ne $null) -and ($ISOPath -ne $null)) {
			$VM | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false
		}
		
		
		$LS_URL="https://" + $VM_Ip + ":7444/lookupservice/sdk"
		
		#SSO
		$SSOkeys = @{"ADMINPASSWORD"="$SSOPassword";
				  	 "SSO_SITE"="Default-First-Site"}
		$SSOPath = $DriveLetter + ":\Single Sign-On\VMware-SSO-Server.msi"
		
		#Inventory Service
		$ISkeys = @{"SSO_ADMIN_PASSWORD"="$SSOPassword";`
					"LS_URL"=$LS_URL;`
					"SSO_ADMIN_USER"="administrator@vsphere.local";`
					"HTTPS_PORT"="10443";`
					"XDB_PORT"="10109";`
					"FEDERATION_PORT"="10111";`
					"QUERY_SERVICE_NUKE_DATABASE"="0";`
					"TOMCAT_MAX_MEMORY_OPTION"="S"}
		$ISPath = $DriveLetter + ":\Inventory Service\VMware vCenter Inventory Service.msi"
		
		#Web Clint
		$WCkeys = @{"SSO_ADMIN_USER"="administrator@vsphere.local";`
					"SSO_ADMIN_PASSWORD"="$SSOPassword";`
					"LS_URL"=$LS_URL}
		$WCPath = $DriveLetter + ':\vSphere-WebClient\VMware-WebClient.exe'

		#vCenter Server
		$VCkeys = @{"SSO_ADMIN_USER"="administrator@vsphere.local";`
					"SSO_ADMIN_PASSWORD"="$SSOPassword";`
					"LS_URL"="$LS_URL";`
					"IS_URL"="https://" + $VM_Ip + ":10443/";`
					"VC_ADMIN_USER"="Administrators";`
					"DB_SERVER_TYPE"="Custom";`
					"DB_DSN"="VCDB";`
					"DB_USERNAME"="Administrator";`
					"DB_PASSWORD"="CENSORED";`
					"VPX_USES_SYSTEM_ACCOUNT"=””;`
					"VPX_ACCOUNT"="TEST\administrator\";`
					"VPX_PASSWORD"="CENSORED";`
					"VPX_PASSWORD_VERIFY"="CENSORED";`
					"INSTALLDIR"="C:\VCServer";`
					"VCS_GROUP_TYPE"="Single";`
					"VCS_HTTPS_PORT"="443";`
					"VCS_HTTP_PORT"="80";`
					"VCS_HEARTBEAT_PORT"="902";`
					"TC_HTTP_PORT"="8080";`
					"TC_HTTPS_PORT"="8443";`
					"VCS_ADAM_LDAP_PORT"="389";`
					"VCS_ADAM_SSL_PORT"="902"}
		$VCPath = $DriveLetter + ':\vCenter-Server\VMware vCenter Server.msi'

		
		#Installations
		#-------------
		
		Write-Host "Installing SSO" -ForegroundColor Blue
#		[String]$command = ""
#		foreach ($currparam in $SSOKeys.keys) {
#			Write-Host "current parameter: $currparam"
#			$command += $currparam + '="' + $SSOKeys.Item($currparam) + '" '
#		}
		$command = (Convert-HashToMSI2 $SSOKeys)
		$SSOScript = $('msiexec.exe /i "' + $SSOPath + '" /qr ' + $command)
		Write-Host "Running the command:"
		Write-Host $SSOscript
		#Invoke-VMScript -ScriptText $SSOScript -GuestCredential $GuestCredential -VM $VM
		pause
		#"msiexec.exe /i " + $InstallPath + "/qr [params]"

		#-----------------------------------
		Write-Host "Installing Inventory Service" -ForegroundColor Blue
#		[String]$command = ""
#		foreach ($currparam in $ISKeys.keys) {
#			$command += $currparam + "='" + $ISKeys.Item($currparam) + "' "
#		}
		$command = (Convert-HashToMSI2 $ISKeys)
		$ISScript = $('msiexec.exe /i "' + $ISPath + '" /qr ' + $command)
		Write-Host "Running the command:"
		Write-Host $ISscript
		#Invoke-VMScript -ScriptText $ISScript -GuestCredential $GuestCredential -VM $VM
		pause
		
		#-----------------------------------
		Write-Host "Installing Web Client" -ForegroundColor Blue
		[String]$command = ""
		foreach ($currparam in $WCKeys.keys) {
			$command += $currparam + '=\"' + $WCKeys.Item($currparam) + '\" '
		}
		$WCScript = $($WCPath + ' /L1033 /v"/qr ' + $command + '"')
		Write-Host "Running the command:"
		Write-Host $WCscript
		#Invoke-VMScript -ScriptText $WCScript -GuestCredential $GuestCredential -VM $VM
		pause

		
		#TODO - Install sql native client x64
		#TODO - Prepare System DSN
		
		#-----------------------------------
		Write-Host "Installing vCenter Server" -ForegroundColor Blue
#		[String]$command = ""
#		foreach ($currparam in $VCKeys.keys) {
#			$command += $currparam + "='" + $VCKeys.Item($currparam) + "' "
#		}
		$command = (Convert-HashToMSI2 $VCKeys)
		$VCscript = $('msiexec.exe /i "' + $VCPath + '" /qr ' + $command)
		Write-Host "Running the command:"
		Write-Host $VCscript
		#Invoke-VMScript -ScriptText $VCscript -GuestCredential $GuestCredential -VM $VM
		pause
	}
}

function Install-DotNetFramework ([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VMname,`
								  [Parameter(Mandatory=$false)][String]$ISODSName,`
								  [Parameter(Mandatory=$false)][String]$ISOPath,`
								  [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential) {
	#Connecting windows disc to the machine
	$(Get-VM -Name $VMname) | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false
	Invoke-VMScript -ScriptText "Install-WindowsFeature Net-Framework-Core -Source D:\sources\sxs"  -GuestCredential $GuestCredential -VM $(Get-VM -Name $VMname) -ScriptType Powershell
}
