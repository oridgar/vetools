<#*************************************************************************************
This file is part of veTools.
Copyright (c) 2013-2014 by Or Idgar.

veTools is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

veTools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Transmission Remote GUI; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
*************************************************************************************#>

#VCD Types (xsd)
#vapp - https://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/etc/1.5/schemas/vcloud/vApp.xsd
#media types - https://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/etc/1.5/schemas/vcloud/media.xsd


function Ignore-VCDSslErrors {
  <#
  .SYNOPSIS
  Ignore SSL errors for VCD, which accept all Certificates.
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
   Ignore-VCDSslErrors
  #>
	add-type @"
	    using System.Net;
	    using System.Security.Cryptography.X509Certificates;
	    public class TrustAllCertsPolicy : ICertificatePolicy {
	        public bool CheckValidationResult(
	            ServicePoint srvPoint, X509Certificate certificate,
	            WebRequest request, int certificateProblem) {
	            return true;
	        }
	    }
"@
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
} 

function Get-BasicAuth ([Parameter(Mandatory=$true)] [System.Management.Automation.PSCredential]$Credential) {
	#preparing utf-8 encoding credentials
	$auth = $Credential.Username + ':' + (Get-STRFromSecureString -Password $Credential.Password)
	
	#Encoding credentials
	$EncodedPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($auth))
	
	#Credentials for authentication on BASE64 encoding
	return @{"Authorization"="Basic $($EncodedPassword)"}
}


function Connect-CIApi {
param(#[Parameter(Mandatory=$false)] [string]$Org = "System",`
	  [Parameter(Mandatory=$true)] [System.Management.Automation.PSCredential]$Credential,`
	  [Parameter(Mandatory=$true)] [string]$server,`
	  [Parameter(Mandatory=$false)] [string]$Version = "1.5"`
	  )
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>

	if ($Credential.UserName -notmatch ".+@.+" -and $Credential.UserName -notmatch "@") {
		throw "No organization name. please enter user name in format <usomver>@<organization>. for global usage put 'System' insead of organization name."
	}
	
	Ignore-VCDSslErrors


	#Headers - credentials & VCD required data
	$global:headers = @{}
	$global:headers += Get-BasicAuth -Credential $Credential
	$global:headers += @{"Accept"=("application/*+xml;version=" + $Version)}

	#Returning result from function and saving session in global variable
	
	$vcdanswer = Invoke-RestMethod -uri ("https://" + $server + "/api/sessions") -Method Post -Headers $headers -SessionVariable global:VCDSession
	# Saves the vcd server name in global variables.
	if ($vcdanswer) {
		[string]$global:vcdserver = $server
	}
	else {
		#Delete the headers from global variables because connection hasn't succeed
		$global:headers = $null
	}
	return $vcdanswer
}

function Disconnect-CIApi ([Parameter(Mandatory=$true)] [string]$server, `
						   [Parameter(Mandatory=$true)] [System.Management.Automation.PSCredential]$Credential,`
	  					   [Parameter(Mandatory=$false)] [string]$Version = "1.5") {
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>

	#Returning result from function and saving session in global variable

	
	#Headers - credentials & VCD required data
	$global:headers = @{}
	$global:headers += Get-BasicAuth -Credential $Credential
	$global:headers += @{"Accept"=("application/*+xml;version=" + $Version)}
	
	$vcdanswer = Invoke-RestMethod -uri ("https://" + $server + "/api/session") -Method Delete -Headers $headers
	# Saves the vcd server name in global variables.
	if ($vcdanswer) {
		$global:headers = $null
	}
	return $vcdanswer
}


function Invoke-VcdMethod {
param([Parameter(Mandatory=$false)] [string]$resource,`
	  [Parameter(Mandatory=$true)] [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,`
	  [Parameter(Mandatory=$false)] [string]$href`
	  )
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
	if (($global:headers -eq $null) -or ($global:vcdSession -eq $null)) {
		Write-Error "No credentials. Please connect to API before by Connect-CIApi"
	}
	elseif ((($server -eq $null) -or ($resource -eq $null)) -and $href -eq $null) {
		Write-Error "No resource reference. Please provide server & resource or href"
	}
	#using href
	elseif ($href) {
		#headers is the credentials + api format and vcd version.
		#websession is the session from the connection before
		Invoke-RestMethod -Uri $href -Method $Method -Headers $headers -WebSession $global:VCDSession
	}
	#using resource
	else {
		Invoke-RestMethod -Uri ("https://" + $global:vcdserver + "/api/" + $resource) -Method $Method -Headers $headers -WebSession $global:VCDSession
	}
}

function Get-CiOriginvApp ([Parameter(Mandatory=$true)]$VApp) {
	<#
  .SYNOPSIS
  Returning the origin vApp template.
  .DESCRIPTION
  Returning the origin vApp template.
  .EXAMPLE
  Get-CiOriginvApp 
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  .LINK
  https://blogs.vmware.com/vsphere/2013/01/which-template-did-that-vapp-get-deployed-from-in-vcloud-director.html
  #>
	$result = Invoke-VcdMethod -resource "query?type=adminEventCBM&filter=(eventType==*vapp/create;entityName==$VApp)" -Method Get
	$json = $result.QueryResultRecords.AdminEventCBMRecord.details | ConvertFrom-Json
	return $json.properties.'vapp.sourceVmContainer.ref'
}

function Get-CIResourceOrder () {
	@("orglist","orgref")
}

function Get-OrgTaskList ([Parameter(Mandatory=$true)]$OrgName) {
	$orglist = Invoke-VcdMethod -resource "org" -Method Get	
	$orgref = $orglist.orglist.org | Where-Object {$_.name -eq $OrgName}
	$org =  Invoke-VcdMethod -href $orgref.href -Method Get
	$tasklistref = $org.Org.link | Where-Object {$_.type -eq "application/vnd.vmware.vcloud.tasksList+xml"}
	$tasklist =  Invoke-VcdMethod -href $tasklistref.href -Method Get
	return $tasklist.TasksList.task
}

function Get-CiLastPowerOffTask([Parameter(Mandatory=$true)]$OrgName) {
	#return Get-OrgTaskList $OrgName | Sort-Object -Unique -Property operation | Sort-Object -Descending -Property starttime | `
	#	Where-Object {$_.operationName -eq "jobUndeploy"}
	return Get-OrgTaskList $OrgName | Where-Object {$_.operationName -eq "jobUndeploy"}
		
		# include vapps
		# Where-Object {$_.operationName -eq "vappUndeployPowerOff" -or $_.operationName -eq "jobUndeploy"}
}

function Get-CiPowerOffDetails ([Parameter(Mandatory=$true)]$OrgName) {
	$TaskList = Get-CiLastPowerOffTask -OrgName $OrgName
	
	$vmdetail_list = @()
	
	foreach ($CurrTask in $tasklist) {
		$vmobject = $(invoke-vcdmethod -href $CurrTask.owner.href -method get)
		$vappobject =  Invoke-VcdMethod -href $($vmobject.vm.link | Where-Object {$_.rel -eq "up"}).href -method get
	
		$vmdetail = "" | select Owner,VMName,VMuuid,vAppName,vAppuuid,OrgName,Date,LastLogin,actionExecuter
		
		$vmdetail.Owner = $vappobject.VApp.Owner.user.name
		$vmdetail.vmname = $vmobject.vm.name
		$vmdetail.vmuuid = $($vmobject.vm.id).split(":")[-1]
		$vmdetail.vAppName = $vappobject.VApp.name
		$vmdetail.vAppuuid = $($vappobject.VApp.id).split(":")[-1]
		$vmdetail.OrgName =$OrgName
		$vmdetail.Date = $CurrTask.startTime # when the user powered off the VM
		#$vmdetail.LastLogin = 
		$vmdetail.actionExecuter = $currtask.user.name #Who performed the action
	
		$vmdetail_list += $vmdetail
	}
	return $vmdetail_list
}

function Get-CIApiVM([Parameter(Mandatory=$true)]$href) {
	return Invoke-VcdMethod -href $href -Method Get
}
#http://technodrone.blogspot.com/2010/01/vcenter-powercli-migration-script.html - automation to copy vcenter to vcenter

function Get-CIApiOrgList() {
	return Invoke-VcdMethod -resource "org" -Method Get
}

function Get-CIApiVmList() {
	Invoke-VcdMethod -resource "vms/query" -Method Get
}

function Get-CIApiVappList() {
	Invoke-VcdMethod -resource "vApps/query" -Method Get
}

function Get-CIApiVdcList() {
	Invoke-VcdMethod -resource "admin/vdcs/query" -Method Get
}

function Get-CIApiDatastoreList() {
	Invoke-VcdMethod -resource "admin/extension/datastores" -Method Get
}

function Get-CIApiExternalNetList() {
	Invoke-VcdMethod -resource "admin/extension/externalnets" -Method Get
}

function Get-CIApiHostRefernceList() {
	Invoke-VcdMethod -resource "admin/extension/hostReferences" -Method Get
}

function Get-CIApiNetworkPoolList() {
	Invoke-VcdMethod -resource "admin/extension/networkPools" -Method Get
}

function Get-CIApiOrgVdcList() {
	Invoke-VcdMethod -resource "admin/extension/orgVdcs/query" -Method Get
}

function Get-CIApiPvdcList() {
	Invoke-VcdMethod -resource "admin/extension/providervdcs" -Method Get
}