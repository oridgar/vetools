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



﻿function Ignore-VCDSslErrors {
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

function Get-STRFromSecureString ([Parameter(Mandatory=$true)] [System.Security.SecureString]$Password) {
	#First convert to binary then to string
	return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(`
		[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
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
