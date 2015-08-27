#Working with managed objects and Get-View instead of property collector

#Stage 1
#-------
$ServiceInstance = Get-View -Id ServiceInstance #Managed Object
$ServiceContent =  $ServiceInstance.Content #Data Object
#Instead of Property Collector we have Get-View so no need to get an object

#Stage 2
#-------
$RootFolderMOR = $ServiceContent.RootFolder #Object Spec
$PropertyList = @("name","overallStatus") #Property Spec

#Stage 3
#-------

#Getting an object with the relevant methods (mapped to vimService?) and fetched properties. using SearchIndex?
$RootFolder = get-view -Id $RootFolderMOR -Property $PropertyList

#Stage 4
#-------
Write-host ("name: " + ($RootFolder.Name))
Write-host ("overallStatus: " + ($RootFolder.OverallStatus))