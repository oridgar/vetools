#Working with managed object references and VimService

$ServiceInstance = Get-View -Id ServiceInstance
$VimService = $ServiceInstance.Client.VimService
$siMOR = New-Object VimApi_55.ManagedObjectReference
$siMOR.value = "ServiceInstance"
$siMOR.type = "ServiceInstance"

#Build all Data Objects
$ServiceContent = $vimService.retrieveServiceContent($siMOR)
#$ServiceContent =  $ServiceInstance.Content
#$pcMOR = $ServiceContent.PropertyCollector
$pcMOR = New-Object VimApi_55.ManagedObjectReference
$pcMOR.Type = "PropertyCollector"
$pcMOR.Value = "propertyCollector"
$rootFolderMOR = $ServiceContent.RootFolder
$oSpec = New-Object VimApi_55.ObjectSpec
$oSpec.Obj = $rootFolderMOR
$pSpec = New-Object VimApi_55.PropertySpec
$pSpec.All = $false
$pSpec.Type = $rootFolderMOR.Type
$pSpec.PathSet = @("name","overallStatus")
$pfss = New-Object VimApi_55.PropertyFilterSpec[] -ArgumentList 1
$pfss[0] = new-object VimApi_55.PropertyFilterSpec
$pfss[0].ObjectSet = @($oSpec)
$pfss[0].PropSet = @($pSpec)

#Get Data Object with the managed object properites and prints it
$objs = $vimService.RetrieveProperties($pcMOR, $pfss)
foreach ($currObj in $objs) {
	foreach ($currProp in $currObj.propSet) {
		Write-host (($currProp.name) + ": " + ($currProp.val))
	}

}

#All methods are in $vimService and not on the managed objects! you can only get managed object reference and property collector to get the properties