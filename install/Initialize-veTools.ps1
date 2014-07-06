# Initialize-veTools.ps1
# Written by Or Idgar
# veTools 2013 - 2014

# --------------------
# Variable Declaration
# --------------------

# ------------
# Code Section
# ------------

function global:prompt{
    # change prompt text
    Write-Host "veTools " -NoNewLine -foregroundcolor Green
    Write-Host ((Get-location).Path + ">") -NoNewLine
    return " "
}

function writespaces([Int]$NumSpaces) {
	for($i=0; $i -lt $NumSpaces; $i++) {
		Write-Host " " -NoNewline
	}
}

# Change window title
$host.ui.RawUI.WindowTitle += " Enhanced with veTools"



$startpos = ($host.UI.RawUI.WindowSize.Width / 2) - ($("-------------------").length / 2)


writespaces $startpos
Write-Host "-------------------" -ForegroundColor Blue
writespaces $startpos
Write-Host "Welcome to veTools!" -ForegroundColor Blue
writespaces $startpos
Write-Host "-------------------" -ForegroundColor Blue
Write-Host
Write-Host "To get veTools command hit Get-veToolsCommand" -ForegroundColor Blue
Write-Host
Write-Host "`tWritten by Or Idgar" -ForegroundColor Blue
Write-Host

#Import-Module 'C:\ProgramData\veTools\veSettings.psm1'
#Import-Module 'C:\ProgramData\veTools\veTools.psm1'
Import-Module veSettings
Import-Module veTools
Import-Module veTools.Common
Import-Module veTools.vcdRestAPI
Import-Module veTools.LabManager
Import-Module veTools.Rep