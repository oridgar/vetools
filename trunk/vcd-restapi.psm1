function Ignore-VCDSslErrors {
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


function Connect-CIApi {
param([Parameter(Mandatory=$true)] [string]$Org,`
	  [Parameter(Mandatory=$true)] [string]$username,`
	  [Parameter(Mandatory=$true)] [string]$upassword,`
	  [Parameter(Mandatory=$true)] [string]$server`
	  )
	Ignore-VCDSslErrors
	#Write-Host -NoNewline "Username:" 
	#$username = Read-Host
	#Write-Host -NoNewline "Password:" 
	#$upassword = Read-Host

	# one string for basic authentication
	$auth = $username + "@" + $Org + ':' + $upassword
	
	#$Encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
	#$EncodedPassword = [System.Convert]::ToBase64String($Encoded)

	#Encoding credentials
	$EncodedPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($auth))
	#Headers - credentials & VCD required data
	$global:headers = @{"Authorization"="Basic $($EncodedPassword)";`
				 		"Accept"="application/*+xml;version=5.1"}
	return Invoke-RestMethod -uri "https://" + $server + "/api/sessions" -Method Post -Headers $headers -SessionVariable global:VCDSession
}

function Invoke-VcdMethod {
param([Parameter(Mandatory=$true)] [string]$server, `
	  [Parameter(Mandatory=$true)] [string]$method,`
	  [Parameter(Mandatory=$true)] [Microsoft.PowerShell.Commands.WebRequestMethod]$methodtype`
	  )
	if ($headers -eq $null) {
		Write-Error "No credentials. Please connect to API before by Connect-CIApi"
	}
	else {
		#headers is the credentials + api format and vcd version.
		#websession is the session from the connection before
		Invoke-RestMethod -Uri ("https://" + $server + "/api/" + $method) -Method $methodtype -Headers $headers -WebSession $global:VCDSession
	}
}