Set-Variable -Name veUser -Scope Global -Value "username"
Set-Variable -Name vCDExist -Scope Global -Value $true
Set-variable -Name ReportDir -Scope Global -Value "E:\veTools\Reports\"
Set-variable -Name veVClist	-Scope Global -value @("vc-dns1")
Set-Variable -Name veVCDName -Scope Global -Value "vcd-dns1"
Set-Variable -Name TemplatesDir -Scope Global -Value "C:\ProgramData\veTools\Templates"

#Constants
#Set-Variable myvar -option Constant -value 100
Set-Variable -Name veSettings -Scope Global -Value @{
veUser = "username"
vCDExist = $true
ReportDir = "E:\veTools\Reports\"
veVClist = @("vc-dns1")
VCDName = "vcd-dns1"
TemplatesDir = "C:\ProgramData\veTools\Templates"
}