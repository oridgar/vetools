$ServiceInstance = Get-View -Id ServiceInstance
$VimService = $ServiceInstance.Client.VimService
$ServiceContent =  $ServiceInstance.Content
$SessionManagerMOR = $ServiceContent.SessionManager

$PropertyCollectorMOR = $ServiceContent.PropertyCollector
$SearchIndex = Get-View -Id SearchIndex

$LicenseManager = Get-View -Id LicenseManager
$AuthorizationManager = Get-View -Id AuthorizationManager
$CustomizationSpecManager = Get-View -Id CustomizationSpecManager
$TaskManager = Get-View -Id TaskManager


#Data Objects
New-Object VMware.Vim.ObjectSpec
New-Object VMware.Vim.PropertySpec
new-object VimApi_55.ManagedObjectReference
#New-Object VMware.Vim.ManagedObjectReference
New-Object VMware.Vim.PropertyFilterSpec[] -ArgumentList 1
new-object VMware.Vim.PropertyFilterSpec