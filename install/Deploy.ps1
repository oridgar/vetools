function Write-Status ([Parameter(Mandatory=$true)] [Boolean]$result)
{
  	$returncode = 0
	if ($result -eq $TRUE) {write-host -ForegroundColor Green "[Succeed]"} else {write-host -ForegroundColor Red "[Failed!]"; $returncode = 1}
}

clear
Write-Host "--------------------"
Write-Host "veTools Installation"
Write-Host "--------------------"
Write-Host
Write-Host "veTools version 0.2"
Write-Host
Write-Host
# Checking if the folder exists
$InstallDir = ("$($($env:PSModulePath).Split(';')[1])")
Write-Host "InstallDir: $InstallDir"
#if (!$InstallDir) {
#	Write-Host "Creating veTools directory into modules directory..." -NoNewline
#	mkdir $InstallDir
#	Write-Status $?
#}

$moduleNames = @("veTools","veTools.Common","veTools.vcdRestAPI","veTools.LabManager","veTools.Rep")

foreach ($module in $moduleNames) {
	Write-Host "Copying $module module..." -NoNewline
	$sourceFile = $("..\" + $module + ".psm1")
	$sourcepsd = $("..\" + $module + ".psd1")
	$destinationFile = $("$InstallDir" + $module + '\')
	New-Item -ItemType Directory -Path $destinationFile -ErrorAction SilentlyContinue
	Copy-Item -Path $sourceFile -Destination $destinationFile 2>&1> $null
	if ($? -eq $true) {
		Write-Status $?
	}
	Copy-Item -Path $sourcepsd -Destination $destinationFile 2>&1> $null
}

#Copy excel templates to program data


Write-Host "."
Write-Host "Initializing veTools with the shell..." -NoNewline
Copy-Item -Path "Initialize-PowerCLIEnvironment_Custom.ps1" -Destination "${env:ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\Scripts\" > $NULL
Copy-Item -Path "Initialize-veTools.ps1" -Destination "${env:ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\Scripts\" > $NULL
Write-Status $?