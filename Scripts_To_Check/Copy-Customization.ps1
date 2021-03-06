param($srcVC,$dstVC,$srcCustName)
$ErrorActionPreference = "Stop"
$sourceCustomization = Get-OSCustomizationSpec -Server $srcVC -Name $srcCustName
if ($sourceCustomization.Count -ne 1) {
	throw System.Exception("Found more than one customization")
}
$csmgr = Get-View -Server $dstVC -Id CustomizationSpecManager
$csmgr.CreateCustomizationSpec($sourceCustomization.ExtensionData)