clear
Write-Host "--------------------"
Write-Host "veTools Installation"
Write-Host "--------------------"
Write-Host
Write-Host "veTools version 0.2"
Write-Host
Write-Host
# Checking if the folder exists
$InstallDir = ("$($($env:PSModulePath).Split(';')[-1])")
#if (!$InstallDir) {
#	Write-Host "Creating veTools directory into modules directory..." -NoNewline
#	mkdir $InstallDir
#	Write-Status $?
#}

$moduleNames = @("veTools","veSettings","veTools.Common","veTools.vcdRestAPI","veTools.LabManager")

foreach ($module in $moduleNames) {
	Write-Host "Copying $module module..." -NoNewline
	$sourceFile = $("..\" + $module + ".psm1")
	$sourcepsd = $("..\" + $module + ".psd1")
	$destinationFile = $("$InstallDir" + $module + '\')
	New-Item -ItemType Directory -Path $destinationFile -ErrorAction SilentlyContinue
	Copy-Item -Path $sourceFile -Destination $destinationFile 2>&1> $null
	Write-Status $?
	Copy-Item -Path $sourcepsd -Destination $destinationFile 2>&1> $null
}

Write-Host "."
Write-Host "Initializing veTools with the shell..." -NoNewline
Copy-Item -Path "Initialize-PowerCLIEnvironment_Custom.ps1" -Destination "${env:ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\Scripts\" > $NULL
Write-Status $?