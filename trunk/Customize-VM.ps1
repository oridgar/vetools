param([Parameter(Mandatory=$true)]$ip, `
	  [Parameter(Mandatory=$true)]$netmask, `
	  [Parameter(Mandatory=$true)]$gateway, `
	  [Parameter(Mandatory=$true)]$dnsServers, `
	  [Parameter(Mandatory=$true)]$Password, `
	  [Parameter(Mandatory=$true)]$domainName, `
	  [Parameter(Mandatory=$true)]$domainAdmin, `
	  [Parameter(Mandatory=$true)]$domainAdminPassword, `
	  [Parameter(Mandatory=$true)]$FullName, `
	  [Parameter(Mandatory=$true)]$OrgName, `
	  [Parameter(Mandatory=$true)][VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VM)

#$serviceInstance = Get-View serviceinstance
#$vcRootFolder = get-view –id  $serviceInstance.Content.RootFolder
#$searchIndex = get-view –id $serviceInstance.Content.SearchIndex	

$vmMO = $VM | get-view

$csmgr = get-view -Id CustomizationSpecManager
#$csmgr.EncryptionKey

$spec = New-Object “VMware.Vim.CustomizationSpec”

$spec.Options = New-Object “VMware.Vim.CustomizationWinOptions”
$spec.Options.ChangeSID = "false"
$spec.Options.DeleteAccounts = $false

$spec.Identity = New-Object “VMware.Vim.CustomizationSysprep”
$spec.Identity.GuiUnattended = New-Object “VMware.Vim.CustomizationGuiUnattended"
$spec.Identity.GuiUnattended.Password = New-Object "VMware.Vim.CustomizationPassword"
$spec.Identity.GuiUnattended.Password.Value = $Password
$spec.Identity.GuiUnattended.Password.PlainText = $true
$spec.Identity.GuiUnattended.TimeZone = 135
$spec.Identity.GuiUnattended.AutoLogon = $false
$spec.Identity.GuiUnattended.AutoLogonCount = 0
$spec.Identity.UserData = New-Object “VMware.Vim.CustomizationUserData"
$spec.Identity.UserData.FullName = $FullName
$spec.Identity.UserData.OrgName = $OrgName
$spec.Identity.UserData.ComputerName = New-Object “VMware.Vim.CustomizationVirtualMachineName"
$spec.Identity.UserData.ProductId = ""

$spec.Identity.Identification = New-Object "VMware.Vim.CustomizationIdentification"
$spec.Identity.Identification.JoinDomain = $domainName
$spec.Identity.Identification.DomainAdmin = $domainAdmin
$spec.Identity.Identification.DomainAdminPassword = New-Object "VMware.Vim.CustomizationPassword"
$spec.Identity.Identification.DomainAdminPassword.Value = $domainAdminPassword
$spec.Identity.Identification.DomainAdminPassword.PlainText = $true

$spec.Identity.LicenseFilePrintData = New-Object "VMware.Vim.CustomizationLicenseFilePrintData"
$spec.Identity.LicenseFilePrintData.AutoMode = "perServer"
$spec.Identity.LicenseFilePrintData.AutoUsers = 5

#Leave this empty
$spec.GlobalIPSettings = New-Object “VMware.Vim.CustomizationGlobalIPSettings”

##$spec.NicSettingMap =  [VMware.Vim.CustomizationAdapterMapping[]] (@())
$spec.NicSettingMap =  New-Object -TypeName VMware.Vim.CustomizationAdapterMapping[] -ArgumentList 1
$spec.NicSettingMap[0] = New-Object "VMware.Vim.CustomizationAdapterMapping"
$spec.NicSettingMap[0].Adapter = New-Object "VMware.Vim.CustomizationIPSettings"
$spec.NicSettingMap[0].Adapter.Ip = New-Object "VMware.Vim.CustomizationFixedIp"
$spec.NicSettingMap[0].Adapter.Ip.IpAddress = $ip
$spec.NicSettingMap[0].Adapter.SubnetMask = $netmask
$spec.NicSettingMap[0].Adapter.Gateway = $gateway
$spec.NicSettingMap[0].Adapter.DnsServerList = $dnsServers

$vmMO.CustomizeVM($spec)

return $spec