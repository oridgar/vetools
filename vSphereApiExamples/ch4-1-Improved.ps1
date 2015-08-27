#Working with managed objects

#Stage 1
#-------
$ServiceInstance = Get-View -Id ServiceInstance
$ServiceContent = $ServiceInstance.Content
$PropertyCollector = Get-View $ServiceContent.PropertyCollector

#Stage 2
--------

#Build all Data Objects for retrieving the properties
#Filter Data Object Spec
$rootFolderMOR = $ServiceContent.RootFolder
$oSpec = New-Object VMware.Vim.ObjectSpec
$oSpec.Obj = $rootFolderMOR

#Property Spec
#Equivalent to $PropertyList = @("name","overallStatus")
$pSpec = New-Object VMware.Vim.PropertySpec
$pSpec.All = $false
$pSpec.Type = $rootFolderMOR.Type
$pSpec.PathSet = @("name","overallStatus")

#Combining Data Objects in one object
$pfss = New-Object VMware.Vim.PropertyFilterSpec[] -ArgumentList 1
$pfss[0] = new-object VMware.Vim.PropertyFilterSpec
$pfss[0].ObjectSet = @($oSpec)
$pfss[0].PropSet = @($pSpec)

#Stage 3
--------

#Get Data Object with the managed object properites and prints it
$objs = $PropertyCollector.RetrieveProperties($pfss)

#Stage 4
#-------

foreach ($currObj in $objs) {
	foreach ($currProp in $currObj.propSet) {
		Write-host (($currProp.name) + ": " + ($currProp.val))
	}
}