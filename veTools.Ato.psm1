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
				$(Get-VM -Name $VM) | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false | Out-Null
			}
			
			#Running Installation
			$Return = Invoke-VMScript -ScriptText $($InstallPath +  " " + $(Get-SQLConfigString -ServiceUser $ServiceUser -ServicePassword $ServicePassword -SAPassword $SAPassword -AdminUser $AdminUser)) -GuestCredential $GuestCredential -VM $(Get-VM -Name $VM)
			return $Return
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
		
		#Powershell Version
		#Import-Module ADDSDeployemnt
		#Install-ADDSForest `
		#-CreateDnsDelegation:$false `
		#-DatabasePath "C:\Windows\NTDS" `
		#-DomainMode "Win2012R2" `
		#-DomainNetbiosName "ETSS" `
		#-ForestMode "Win2012R2" `
		#-InstallDns:$true `
		#-LogPath "C:\Windows\NTDS" `
		#-NoRebootOnCompletion:$false `
		#-SysvolPath "C:\Windows\SYSVOL" `
		#-Force:$true

		#For Windows 2008R2
		Invoke-VMScript -VM $vm -GuestCredential $GuestCredential -ScriptType Bat -ScriptText $("dcpromo /unattend /InstallDns:yes /dnsOnNetwork:yes /replicaOrNewDomain:domain /newDomain:forest /newDomainDnsName:$DomainName /DomainNetbiosName:" + $DomainName.Split('.')[0] + " /databasePath:`"C:\Windows\NTDS`" /logPath:`"C:\Windows\NTDS`" /sysvolpath:`"C:\Windows\SYSVOL`" /safeModeAdminPassword:$AdminPassword /forestLevel:2 /domainLevel:2 /rebootOnCompletion:yes")
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
						  [Parameter(Mandatory=$false)][String]$ISODSName, [Parameter(Mandatory=$false)][String]$ISOPath,`
						  [Parameter(Mandatory=$false)][Switch]$UseSystemAccount=$true,`
						  [Parameter(Mandatory=$false)][String]$SqlServerName="localhost",`
						  [Parameter(Mandatory=$false)][String]$DatabaseName="VCDB") {
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
		#for installation guide - http://www.vmware.com/files/pdf/techpaper/vcenter_server_cmdline_install.pdf
		$VM = $(Get-VM -Name $VMname)
		$VM_Ip = $VM.Guest.IPAddress[0]
		$LS_URL="https://" + $VM_Ip + ":7444/lookupservice/sdk"
		$SSOPath = $DriveLetter + ":\Single Sign-On\VMware-SSO-Server.msi"
		$VCPath = $DriveLetter + ':\vCenter-Server\VMware-vcserver.exe'
		$ISPath = $DriveLetter + ":\Inventory Service\VMware vCenter Inventory Service.msi"
		$WCPath = $DriveLetter + ':\vSphere-WebClient\VMware-WebClient.exe'
		$SSO_admin_user = "administrator@vsphere.local"
		$DSN_Name = $DatabaseName

		$batchFile = 'c:\vcinst.cmd'

		#------------------
		#Setting parameters
		#------------------
		
		#vCenter Server
		#--------------
		
		#Configured for windows authentication
		$VCkeys = @{"DB_SERVER_TYPE"="Custom";`
					"DB_DSN"=$DSN_Name;`
					"FORMAT_DB"="1";`
					"DB_DSN_WINDOWS_AUTH"="1"}
					#Only relevant if using SQL authentication
					#"DB_USERNAME"="Administrator";`
					#"DB_PASSWORD"="$SSOPassword";`

		#Installation configuration (Linked Mode and Tomcat properties)
		$VCkeys += @{"VCS_GROUP_TYPE"="Single";`
					 "JVM_MEMORY_OPTION"="S"}					
					#"INSTALLDIR"="C:\VCServer";`
		
		#Connection and registration to SSO and Inventory Services
		$VCkeys += @{"SSO_ADMIN_USER"="$SSO_admin_user";`
					"SSO_ADMIN_PASSWORD"="$SSOPassword";`
					"LS_URL"="$LS_URL";`
					"IS_URL"="https://" + $VM_Ip + ":10443/"}
		
		#Services credentials
		if ($UseSystemAccount -eq $true) {
			#Using Local System account for the services
			$VCkeys += @{"VPX_USES_SYSTEM_ACCOUNT"="1"}
		}
		else {
			$guest_password = Get-STRFromSecureString -Password $GuestCredential.Password
			$guest_user = $GuestCredential.UserName
			$VCkeys += @{"VPX_USES_SYSTEM_ACCOUNT"="";`
						 "VPX_ACCOUNT"="$guest_user";`
					 	 "VPX_PASSWORD"="$guest_password";`
					 	 "VPX_PASSWORD_VERIFY"="$guest_password"}
					 	 #"VPX_ACCOUNT_UPN"="Administrator"		
		}

		#Permissions on VC (default setting)
		$VCkeys += @{"VC_ADMIN_USER"="administrator@vsphere.local";`
					 "VC_ADMIN_IS_GROUP_VPXD_TXT"="false"}
					 
		#Ports (default setting)
		$VCkeys += @{"VCS_ADAM_LDAP_PORT"="389";`
					"VCS_ADAM_SSL_PORT"="636";`
					"VCS_HTTPS_PORT"="443";`
					"VCS_HTTP_PORT"="80";`
					"VCS_HEARTBEAT_PORT"="902";`
					"TC_HTTP_PORT"="8080";`
					"TC_HTTPS_PORT"="8443"}

		#-------------
		#Installations
		#-------------
		
		#Mounting installation iso before
		Write-Host "Mounting CDROM" -ForegroundColor Blue
		if (($ISODSName -ne $null) -and ($ISOPath -ne $null)) {
			$VM | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false | Out-Null
		}
		
		Write-Host "Creating new installation batch file" -ForegroundColor Blue
		Invoke-VMScript -ScriptText $("type NUL > $batchfile") -GuestCredential $GuestCredential -VM $VM -ScriptType Bat | Out-Null
		
		Write-Host "Installing SSO" -ForegroundColor Blue
		Install-SSO -VM $VM `
					-GuestCredential $GuestCredential `
					-SSOPath $SSOPath `
					-SSOPassword $SSOPassword `
					-batchFile $batchFile
		#pause

		Write-Host "Installing Inventory Service" -ForegroundColor Blue
		Install-IS 	-VM $VM `
					-GuestCredential $GuestCredential `
					-ISPath $ISPath `
					-LS_URL $LS_URL `
					-SSO_admin_user $SSO_admin_user `
					-SSOPassword $SSOPassword `
					-batchFile $batchFile
		#pause
		
		Write-Host "Installing Web Client" -ForegroundColor Blue
		Install-WebClient -VM $VM `
						  -GuestCredential $GuestCredential `
						  -LS_URL $LS_URL `
						  -SSO_admin_user $SSO_admin_user `
						  -SSOPassword $SSOPassword `
						  -batchFile $batchFile
		#pause

		Write-Host "Prerequisites for VC:"
		Write-Host "Configure new database named VCDB - Manual"
		#DISABLE ALL PAUSE FOR NON INTERACTIVE!
		#pause
		
		#$a = [scriptblock]::create($(Get-Content New-DB.ps1))
		#$newDBscript = ${Function:New-SQLDB}
		
		#TODO - Create new database named VCDB
		#Owner of the DB - NT AUTHORITY\SYSTEM
		#Initial size data - 100MB autogrowth by 100MB unlimited
		#Initial size log - 100MB autogrouwth by 10% unlimited
		#Recovery model - Simple
		#permissions to NT AUTHORITY\SYSTEM AS db_owner
		
		Write-Host "Install sql native client x64 on VC server - Manual" -ForegroundColor Blue
		#driver - SQL Server Native Client 11.0
		#DISABLE ALL PAUSE FOR NON INTERACTIVE!
		#pause
		Write-Host "Prepare System DSN" -ForegroundColor Blue
		#Name - VCDB
		#Server - localhost
		#windows authentication
		#Default database - VCDB

		$addDsnCommand = "Add-OdbcDsn -Name " + $DSN_Name + `
									" -DriverName 'SQL Server Native Client 11.0' " + `
									"-DsnType System " + `
									"-SetPropertyValue @('Trusted_Connection=Yes','Server=" + $SqlServerName + "','Database=" + $DatabaseName + "')"
		Invoke-VMScript -ScriptText $addDsnCommand -GuestCredential $GuestCredential -VM $VM -ScriptType Powershell | Out-Null
		Write-Host "Make sure SQL Server Agent service is started" -ForegroundColor Blue
		$startSqlAgentCommand = "Start-Service SQLSERVERAGENT"
		Invoke-VMScript -ScriptText $startSqlAgentCommand -GuestCredential $GuestCredential -VM $VM -ScriptType Powershell | Out-Null
		
		if ($UseSystemAccount -eq $true) {
			Write-Host "Make sure local system account has permissions to SQL"
			Write-Host "This means that 'NT AUTHORITY\SYSTEM' must be mapped to VCDB with"
			Write-Host "Default Schema dbo and role db_owner"
			#DISABLE ALL PAUSE FOR NON INTERACTIVE!
			#pause
		}

		#TODO - Make sure if you need to grant "Log on as a service" right to administrator account
		
		Write-Host "Installing vCenter Server" -ForegroundColor Blue
		#TODO - Replace the following command creator with the function
		[String]$command = ""
		foreach ($currparam in $VCKeys.keys) {
			$command += $currparam + '=\"' + $VCKeys.Item($currparam) + '\" '
		}
		$VCScript = $("echo " + $VCPath + ' /L1033 /v"/qr ' + $command + '"' + " >> $batchFile")
		Write-Host "Running the command:"
		Write-Host $VCscript
		#Write-Host "Install manually"
		#Invoke-VMScript -ScriptText $('echo ' + $VCscript + ' > C:\instvc.bat') -GuestCredential $GuestCredential -VM $VM -ScriptType Bat
		$Result = Invoke-VMScript -ScriptText $($VCscript) -GuestCredential $GuestCredential -VM $VM -ScriptType Bat
		if ($Result.ExitCode -ne 0) {
			throw "Failed installing VC"
		}
		
		#TODO - the installer returns the following message:
		#"Warning 32014.A utility for phone home data collector couldn't be executed successfully.
		#Please see its log file (with name PhoneHome) and vminst.log in system temporary folder for more details.
		#Please note that you can also enable / disable this feature after installation through the application user interface."
	}
}

function Install-SSO ([Parameter(Mandatory=$true)]$VM,`
					  [Parameter(Mandatory=$true)]$GuestCredential,`
					  [Parameter(Mandatory=$true)]$SSOPath,`
					  [Parameter(Mandatory=$true)]$SSOPassword,`
					  [Parameter(Mandatory=$true)]$batchFile) {
	$SSOkeys = @{"ADMINPASSWORD"="$SSOPassword";
			  	 "SSO_SITE"="Default-First-Site"}
	Write-Host "Installing SSO" -ForegroundColor Blue
	$command = (Convert-HashToMSI2 $SSOKeys)
	$SSOScript = $('echo ' + 'msiexec.exe /i "' + $SSOPath + '" /qr ' + $command + ">> $batchFile")
	Write-Host "Running the command:"
	Write-Host $SSOscript
	$Result= Invoke-VMScript -ScriptText $SSOScript -GuestCredential $GuestCredential -VM $VM -ScriptType Bat
	if ($Result.ExitCode -ne 0) {
		throw "Failed installing SSO"
	}
	
}

function Install-IS ([Parameter(Mandatory=$true)]$VM,`
					 [Parameter(Mandatory=$true)]$GuestCredential,`
					 [Parameter(Mandatory=$true)]$ISPath,`
					 [Parameter(Mandatory=$true)]$LS_URL,`
					 [Parameter(Mandatory=$true)]$SSO_admin_user,`
					 [Parameter(Mandatory=$true)]$SSOPassword,`
					 [Parameter(Mandatory=$true)]$batchFile) {
	$ISkeys = @{"SSO_ADMIN_PASSWORD"="$SSOPassword";`
				"LS_URL"=$LS_URL;`
				"SSO_ADMIN_USER"="$SSO_admin_user";`
				"HTTPS_PORT"="10443";`
				"XDB_PORT"="10109";`
				"FEDERATION_PORT"="10111";`
				"QUERY_SERVICE_NUKE_DATABASE"="0";`
				"TOMCAT_MAX_MEMORY_OPTION"="S"}
	Write-Host "Installing Inventory Service" -ForegroundColor Blue
	$command = (Convert-HashToMSI2 $ISKeys)
	$ISScript = $('echo ' + 'msiexec.exe /i "' + $ISPath + '" /qr ' + $command + ">> $batchFile")
	Write-Host "Running the command:"
	Write-Host $ISscript
	$Result = Invoke-VMScript -ScriptText $ISScript -GuestCredential $GuestCredential -VM $VM -ScriptType Bat
	if ($Result.ExitCode -ne 0) {
		throw "Failed installing Inventory Service"
	}
}

function Install-WebClient ([Parameter(Mandatory=$true)]$SSO_admin_user,`
							[Parameter(Mandatory=$true)]$SSOPassword,`
							[Parameter(Mandatory=$true)]$LS_URL,`
							[Parameter(Mandatory=$true)]$GuestCredential,`
							[Parameter(Mandatory=$true)]$VM,`
							[Parameter(Mandatory=$true)]$batchFile) {
	$WCkeys = @{"SSO_ADMIN_USER"="$SSO_admin_user";`
				"SSO_ADMIN_PASSWORD"="$SSOPassword";`
				"LS_URL"=$LS_URL}
	Write-Host "Installing Web Client" -ForegroundColor Blue
	#TODO - Replace the following command creator with the function
	[String]$command = ""
	foreach ($currparam in $WCKeys.keys) {
		$command += $currparam + '=\"' + $WCKeys.Item($currparam) + '\" '
	}
	$WCScript = $('echo ' + $WCPath + ' /L1033 /v"/qr ' + $command + '"' + ">> $batchFile")
	Write-Host "Running the command:"
	Write-Host $WCscript
	$Result = Invoke-VMScript -ScriptText $WCScript -GuestCredential $GuestCredential -VM $VM -ScriptType Bat
	if ($Result.ExitCode -ne 0) {
		throw "Failed installing SSO"
	}
}

function Install-DotNetFramework ([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VMname,`
								  [Parameter(Mandatory=$false)][String]$ISODSName,`
								  [Parameter(Mandatory=$false)][String]$ISOPath,`
								  [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$GuestCredential) {
	#Connecting windows disc to the machine
	$(Get-VM -Name $VMname) | Get-CDDrive | Set-CDDrive -IsoPath $("[$ISODSName] $ISOPath") -Connected:$true -Confirm:$false | Out-Null
	$Result = Invoke-VMScript -ScriptText "Install-WindowsFeature Net-Framework-Core -Source D:\sources\sxs"  -GuestCredential $GuestCredential -VM $(Get-VM -Name $VMname) -ScriptType Powershell
	if ($Result.ExitCode -ne 0) {
		throw "Failed installing .NET framework"
	}
}

function Invoke-VMScriptInteractive ($VM,$user,$password,$script,[VMware.VimAutomation.ViCore.Types.V1.ScriptType]$scriptType) {
	$ServiceInstance = get-view -Id ServiceInstance
	$GuestOperationsManager = Get-View -Id ($ServiceInstance.Content.GuestOperationsManager)
	$ProcessManager = get-view -id $GuestOperationsManager.ProcessManager

	#Guest Program Specification
	$guestProgSpec = New-Object -TypeName "VMware.Vim.GuestProgramSpec"
	$guestProgSpec.envVariables = $null;
	
	#scriptblock
	if ($scriptType -eq [VMware.VimAutomation.ViCore.Types.V1.ScriptType]::Bash) {
		$guestProgSpec.programPath = "/bin/sh";
		$guestProgSpec.workingDirectory = "~/";
		$guestProgSpec.arguments = "-c " + $script;
	}
	elseif ($scriptType -eq [VMware.VimAutomation.ViCore.Types.V1.ScriptType]::Bat) {
		$guestProgSpec.programPath = 'C:\Windows\System32\cmd.exe';
		$guestProgSpec.workingDirectory = 'c:\';
		#$guestProgSpec.workingDirectory = '%userprofile%\';
		$guestProgSpec.arguments = "/c " + $script;
	}
	elseif ($scriptType -eq [VMware.VimAutomation.ViCore.Types.V1.ScriptType]::Powershell) {
		$guestProgSpec.programPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
		$guestProgSpec.workingDirectory = 'C:\Windows\System32\WindowsPowerShell\v1.0\';
		$guestProgSpec.arguments = $script;
	}
	
	#Guest authentication
	$guestAuth = New-Object -TypeName "VMware.Vim.NamePasswordAuthentication"
	$guestAuth.InteractiveSession = $true;
	$guestAuth.username = $user;
	$guestAuth.password = $password;
	
	$VMMOR = $VM.ExtensionData.MoRef
	$Result = $ProcessManager.startProgramInGuest($VMMOR, $guestAuth , $guestProgSpec);
	return $Result
}

function Invoke-VMScriptExternal ($ScriptType,$ScriptFile,$VM,$WhatIf,$Confirm,$GuestCredential,$GuestPassword,$GuestUser,$HostCredential,$HostPassword,$HostUser,$RunAsync,$Server,$ToolsWaitSecs) {
	$ScriptText = Get-Content -Raw -Path $ScriptFile
	Invoke-VMScript -ScriptType $scriptType `
					-VM $VM `
					-WhatIf $WhatIf `
					-Confirm $Confirm`
					-GuestPassword $GuestPassword `
					-GuestUser $GuestUser `
					-RunAsync $RunAsync `
					-ScriptText $ScriptText
}

function New-DB ([Parameter(Mandatory=$false)]$DBName = 'VCDB') {
	#Creates a new database using our specifications
	$ErrorActionPreference = "Stop"
	try {
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')  | out-null
		$s = new-object ('Microsoft.SqlServer.Management.Smo.Server')

		# Instantiate the database object and add the filegroups
		$db = new-object ('Microsoft.SqlServer.Management.Smo.Database') ($s, $dbname)
		$sysfg = new-object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($db, 'PRIMARY')
		$db.FileGroups.Add($sysfg)

		# Create the file for the system tables
		$syslogname = $dbname
		$dbdsysfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($sysfg, $syslogname)
		$sysfg.Files.Add($dbdsysfile)
		$dbdsysfile.FileName = $s.Information.MasterDBPath + '\' + $syslogname + '.mdf'
		$dbdsysfile.Size = [double](100.0 * 1024.0)
		$dbdsysfile.GrowthType = 'Percent'
		$dbdsysfile.Growth = 10.0
		$dbdsysfile.IsPrimaryFile = 'True'

		# Create the file for the log
		$loglogname = $dbname + '_log'
		$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($db, $loglogname)
		$db.LogFiles.Add($dblfile)
		$dblfile.FileName = $s.Information.MasterDBLogPath + '\' + $loglogname + '.ldf'
		$dblfile.Size = [double](10.0 * 1024.0)
		$dblfile.GrowthType = 'Percent'
		$dblfile.Growth = 25.0
		# Create the database
		$db.Create()

		$db.SetOwner('NT AUTHORITY\SYSTEM')
		$db.RecoveryModel = "Simple"
		$db.Alter()
	}
	catch [System.Exception] {
		exit 1
	}
}