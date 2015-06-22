$serviceInstance = Get-View serviceinstance
$vcRootFolder = get-view –id  $serviceInstance.Content.RootFolder
$searchIndex = get-view –id $serviceInstance.Content.SearchIndex	

$vmMO = Get-VM | get-view

$spec = New-Object “VMware.Vim.CustomizationSpec”

$spec.Options = New-Object “VMware.Vim.CustomizationWinOptions”
$spec.Options.ChangeSID =$false
$spec.Options.DeleteAccounts =$false

$spec.Identity = New-Object “VMware.Vim.CustomizationSysprep”
$spec.Identity.GuiUnattended
$spec.Identity
$spec.Identity

$spec.GlobalIPSettings = New-Object “VMware.Vim.CustomizationGlobalIPSettings”

#ARRAY!!!
$spec.NicSettingMap = New-Object “VMware.Vim.CustomizationAdapterMapping”

#$vmMO.CustomizeVM($spec)