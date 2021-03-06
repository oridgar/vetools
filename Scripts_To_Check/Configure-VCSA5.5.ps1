param($VcsaName,$License,$Administrators,$SsoPassword)

Write-Host "Add Identity Sources"
Pause
Write-Host "Add users to vsphere.local administrators group"
Pause

$viServer = Connect-VIServer $VcsaName
$ServiceInstance = $viServer.Extensiondata

#$licenseMgr = Get-LicenseDataManager -Server $viserver
$licenseMgr = get-view -Id "LicenseManager" -Server $viServer
$licenseAssignMgr = Get-View -Id $licenseMgr.LicenseAssignmentManager -Server $viServer

#Registering the license and assigning to the VC
$licenseObj = $licenseMgr.AddLicense($License,$null)
$licenseAssignMgr.UpdateAssignedLicense(($ServiceInstance.Content.About.InstanceUuid),$License,$null)

foreach ($currAdmin in $Administrators) {
	New-VIPermission -Entity "Datacenters" -Role "Admin" -Principal $currAdmin -Propagate $true -Server $viServer
}