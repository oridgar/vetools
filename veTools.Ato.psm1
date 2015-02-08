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
						  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$VM, [Parameter(Mandatory=$true)][String]$InstallPath,`
						  [Parameter(Mandatory=$true)][String]$ServiceUser,[Parameter(Mandatory=$true)][String]$AdminUser,`
						  [Parameter(Mandatory=$true)][String]$ServicePassword, [Parameter(Mandatory=$true)][String]$SAPassword,`
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
		$ssoInst = `
		" "
	}
	process {
	
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
