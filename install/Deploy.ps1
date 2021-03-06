function Write-Status ([Parameter(Mandatory=$true)] [Boolean]$result)
{
  	$returncode = 0
	if ($result -eq $TRUE) {write-host -ForegroundColor Green "[Succeed]"} else {write-host -ForegroundColor Red "[Failed!]"; $returncode = 1}
}

function Test-IsAdmin {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

if (!(Test-IsAdmin)) {
	Write-Host "Warning: the session is not elevated with administrator priviledge. Please run as administrator" -ForegroundColor Yellow
	exit 1
}

[xml]$Appdata = Get-Content ../veTools.xml
$SourceDir = "..\"

clear
Write-Host "--------------------"
Write-Host "veTools Installation"
Write-Host "--------------------"
Write-Host
Write-Host $("veTools version "+ $Appdata.veTools.Version)
Write-Host
Write-Host
# Checking if the folder exists
$InstallDir = ("$($PSHOME + '\Modules\')")
Write-Host "InstallDir: $InstallDir"
#if (!$InstallDir) {
#	Write-Host "Creating veTools directory into modules directory..." -NoNewline
#	mkdir $InstallDir
#	Write-Status $?
#}

#List of all modules
#TODO - change it to read all psm1 files dynamically
$moduleNames = @("veTools","veTools.Common","veTools.vcdRestAPI","veTools.LabManager","veTools.Rep","veTools.Ato","veTools.Maintain","veTools.sql")

foreach ($module in $moduleNames) {
	Write-Host "Copying $module module..." -NoNewline
	$sourceFile = $("..\" + $module + ".psm1")
	$sourcepsd = $("..\" + $module + ".psd1")
	$destinationFile = $("$InstallDir" + $module + '\')
	New-Item -ItemType Directory -Path $destinationFile -ErrorAction SilentlyContinue | Out-Null
	Copy-Item -Path $sourceFile -Destination $destinationFile 2>&1> $null
	if ($? -eq $true) {
		Write-Status $?
	}
	Copy-Item -Path $sourcepsd -Destination $destinationFile 2>&1> $null
}

#Copy excel templates to program data

Write-Host 
Write-Host "Initializing veTools with the PowerCLI shell..." -NoNewline

#Getting custom file name
$customfile = "${env:ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment_Custom.ps1" 
# check if the call for veTools exists

if ((get-content $customfile -ErrorAction SilentlyContinue| where-object {$_ -match "\\Initialize-veTools.ps1`"$"}) -eq $null) {
	#adding new line to the file.
write-output '&"${env:ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-veTools.ps1"' >> $customfile

}
#Copy the veTools initialization file to PowerCLI scripts folder
Copy-Item -Path "Initialize-veTools.ps1" -Destination "${env:ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\Scripts\" > $NULL
Write-Status $?

if (($PSVersionTable.PSVersion.Major) -lt 4) {
	Write-Host "Warning - your powershell version is lower than 4. you have to update before using veTools" -ForegroundColor Yellow
	Write-Host "Install .Net framework 4.5.1 first from http://www.microsoft.com/en-us/download/details.aspx?id=40779" -ForegroundColor Yellow
	Write-Host "Download powershell4 from http://www.microsoft.com/en-us/download/details.aspx?id=40855" -ForegroundColor Yellow
}