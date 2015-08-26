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

function Ignore-SslErrors {
	# Create a compilation environment
	$Provider=New-Object Microsoft.CSharp.CSharpCodeProvider
	$Compiler=$Provider.CreateCompiler()
	$Params=New-Object System.CodeDom.Compiler.CompilerParameters
	$Params.GenerateExecutable=$False
	$Params.GenerateInMemory=$True
	$Params.IncludeDebugInformation=$False
	$Params.ReferencedAssemblies.Add("System.DLL") > $null
	$TASource=@'
	  namespace Local.ToolkitExtensions.Net.CertificatePolicy {
	    public class TrustAll : System.Net.ICertificatePolicy {
	      public TrustAll() { 
	      }
	      public bool CheckValidationResult(System.Net.ServicePoint sp,
	        System.Security.Cryptography.X509Certificates.X509Certificate cert, 
	        System.Net.WebRequest req, int problem) {
	        return true;
	      }
	    }
	  }
'@ 
	$TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
	$TAAssembly=$TAResults.CompiledAssembly

	## We now create an instance of the TrustAll and attach it to the ServicePointManager
	$TrustAll=$TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
	[System.Net.ServicePointManager]::CertificatePolicy=$TrustAll
}

function New-ObjectFromProxy {
	param($proxy, $proxyAttributeName, $typeName)

	# Locate the assembly for $proxy
	$attribute = $proxy | gm | where { $_.Name -eq $proxyAttributeName }
	$str = "`$assembly = [" + $attribute.TypeName + "].assembly"
	invoke-expression $str

	# Instantiate an AuthenticationHeaderValue object.
	$type = $assembly.getTypes() | where { $_.Name -eq $typeName }
	return $assembly.CreateInstance($type)
}

function Connect-LabManager {
	param
    (
        [string] $server, 
        $credential,
        [string] $organizationname = "Default",
        [string] $workspacename = "Main"
    )
        
	# Log in to Lab Manager's web service.
	$server = "https://" + $server + "/"
	$endpoint = $server + "LabManager/SOAP/LabManager.asmx"
	$proxy = new-webserviceproxy -uri $endpoint -cred $credential

	# Before continuing we need to add an Authentication Header to $proxy.
	$authHeader = New-ObjectFromProxy -proxy $proxy -proxyAttributeName "AuthenticationHeaderValue" -typeName "AuthenticationHeader"
	$authHeader.username = $credential.GetNetworkCredential().UserName
	$authHeader.password = $credential.GetNetworkCredential().Password
    $authHeader.organizationname = $organizationname
    $authHeader.workspacename = $workspacename
	$proxy.AuthenticationHeaderValue = $authHeader
	return $proxy
}

function Get-LabManagerInternal
{
	param
	(
		[string] $server = $(throw "Parameter -Server [System.String] is required."),
		$credential = $(get-credential),
		[string] $organizationname = "Global",
		[string] $workspacename = "Main"
	)
	
	$labManagerInternalUri = [System.Uri] "https://$server/LabManager/SOAP/LabManagerInternal.asmx"
	$proxy = New-WebServiceProxy -Uri $labManagerInternalUri -Credential $credential
	
	if ($proxy)
	{
		# Before continuing we need to add an Authentication Header to $proxy.
		$authHeader = New-ObjectFromProxy -proxy $proxy -proxyAttributeName "AuthenticationHeaderValue" -typeName "AuthenticationHeader"
		$authHeader.username = $credential.GetNetworkCredential().UserName
		$authHeader.password = $credential.GetNetworkCredential().Password
		$authHeader.organizationname = $organizationname
		$authHeader.workspacename = $workspacename
		$proxy.AuthenticationHeaderValue = $authHeader
		return $proxy
	}
}