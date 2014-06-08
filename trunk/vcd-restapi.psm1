function Ignore-VCDSslErrors {
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
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
param([Parameter(Mandatory=$false)] [string]$Org = "System",`
	  [Parameter(Mandatory=$true)] [System.Management.Automation.PSCredential]$Credential,`
	  [Parameter(Mandatory=$true)] [string]$server`
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

	# one string for basic authentication
	#$auth = $username + "@" + $Org + ':' + $upassword
	
	#Encoding credentials
	#$EncodedPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($auth))
	#Headers - credentials & VCD required data
	$global:headers += Get-BasicAuth -Credential $Credential
	$global:headers += @{"Accept"="application/*+xml;version=5.1"}
	#$global:headers = @{"Authorization"="Basic $($EncodedPassword)";`
	#			 		"Accept"="application/*+xml;version=5.1"}
	
	return Invoke-RestMethod -uri ("https://" + $server + "/api/sessions") -Method Post -Headers $headers -SessionVariable global:VCDSession
}

function Invoke-VcdMethod {
param([Parameter(Mandatory=$true)] [string]$server, `
	  [Parameter(Mandatory=$true)] [string]$resource,`
	  [Parameter(Mandatory=$true)] [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,`
	  [string]$href`
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
	else {
		#headers is the credentials + api format and vcd version.
		#websession is the session from the connection before
		Invoke-RestMethod -Uri ("https://" + $server + "/api/" + $resource) -Method $Method -Headers $headers -WebSession $global:VCDSession
	}
}