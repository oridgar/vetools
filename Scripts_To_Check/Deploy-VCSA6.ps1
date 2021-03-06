param([Parameter(Mandatory=$True)][String]$Password,
	  [Parameter(Mandatory=$True)][String]$HostedESX,
	  [Parameter(Mandatory=$True)][String]$HostedEsxPassword,
	  [Parameter(Mandatory=$True)][String]$HostedDatastore,
	  [Parameter(Mandatory=$True)][String]$PortGroupName,
	  [Parameter(Mandatory=$True)][String]$ApplianceName,
	  [Parameter(Mandatory=$True)][String]$IsoDriveLetter,
	  [Parameter(Mandatory=$False)][Switch]$DHCP,
	  [Parameter(Mandatory=$False)][String[]]$Domain,
	  [Parameter(Mandatory=$False)][String]$IP,
	  [Parameter(Mandatory=$False)][String]$Gateway,
	  [Parameter(Mandatory=$False)][String]$MaskBits,
	  [Parameter(Mandatory=$False)][String[]]$DnsServers,
	  [Parameter(Mandatory=$False)][String[]]$PscServer = "")

$ErrorActionPreference="Stop"
$TemplatesDir = ".\Templates\VCSA6"

#Checking that the user is connected to any VC
if ((Test-IsVcConnected) -eq $false) {
	Write-Host "No VC Connected. Exiting..." -ForegroundColor Red
	exit 1
}

#Getting relevant data from hosting VC

#Get-Cluster
#Get-VMHost


#Getting configuration template file to build an class object from it.
$ConfigSpec = ConvertFrom-Json (get-content ($TemplatesDir + "\full_conf_vetools.json") -Raw)

$ConfigSpec.__comments = @()

$ConfigSpec.deployment.__comments = ""
$ConfigSpec.deployment.'esx.hostname' = $HostedESX
$ConfigSpec.deployment.'esx.datastore' =  $HostedDatastore
$ConfigSpec.deployment.'esx.username' = "root"
$ConfigSpec.deployment.'esx.password' = $HostedEsxPassword
if ($PscServer -ne "" -and $PscServer -ne $null) {
	$ConfigSpec.deployment.'deployment.option' = "management-tiny"
} else {
	$ConfigSpec.deployment.'deployment.option' = "tiny"
}
$ConfigSpec.deployment.'deployment.network' = $PortGroupName
$ConfigSpec.deployment.'appliance.name' = $ApplianceName
$ConfigSpec.deployment.'appliance.thin.disk.mode' = $false

$ConfigSpec.vcsa.__comments = ""
$ConfigSpec.vcsa.system.__comments = ""
$ConfigSpec.vcsa.system.'root.password' = $Password
$ConfigSpec.vcsa.system.'ssh.enable' = $true
$ConfigSpec.vcsa.system.'time.tools-sync' = $true
$ConfigSpec.vcsa.system.'ntp.servers' = ""
$ConfigSpec.vcsa.system.'platform.service.controller' = $PscServer

$ConfigSpec.vcsa.database.type = "embedded"
$ConfigSpec.vcsa.database.__comments = ""
$ConfigSpec.vcsa.database.user = ""
$ConfigSpec.vcsa.database.password = ""
$ConfigSpec.vcsa.database.servername = ""
$ConfigSpec.vcsa.database.serverport = ""
$ConfigSpec.vcsa.database.provider = ""
$ConfigSpec.vcsa.database.instance = ""

$ConfigSpec.vcsa.sso.__comments = ""
$ConfigSpec.vcsa.sso.password = $Password
$ConfigSpec.vcsa.sso.'domain-name' = "vsphere.local"
$ConfigSpec.vcsa.sso.'site-name' = "Default-First-Site"
$ConfigSpec.vcsa.sso.'first-instance' = $true
$ConfigSpec.vcsa.sso.'replication-partner-hostname' = ""

$ConfigSpec.vcsa.networking.__comments = ""
$ConfigSpec.vcsa.networking.'ip.family' = "ipv4"
if ($DHCP -eq $true) {
	$ConfigSpec.vcsa.networking.mode = "dhcp"
	$ConfigSpec.vcsa.networking.ip = ""
	$ConfigSpec.vcsa.networking.prefix = ""
	$ConfigSpec.vcsa.networking.gateway = ""
	$ConfigSpec.vcsa.networking.'dns.servers' = ""
} else {
	$ConfigSpec.vcsa.networking.mode = "static"
	$ConfigSpec.vcsa.networking.ip = $IP
	$ConfigSpec.vcsa.networking.prefix = $MaskBits
	$ConfigSpec.vcsa.networking.gateway = $Gateway
	
	#$ConfigSpec.vcsa.networking.'dns.servers' = @()
	#$ConfigSpec.vcsa.networking.'dns.servers' += $DnsServers
	
	$ConfigSpec.vcsa.networking.'dns.servers' = ""
	$i=1
	foreach ($currDns in $DnsServers) {
		$ConfigSpec.vcsa.networking.'dns.servers' += $currDns
		if ($i -lt $($DnsServers.count)) {
			$ConfigSpec.vcsa.networking.'dns.servers' += ","
		}
		$i++
	}
}
$ConfigSpec.vcsa.networking.'system.name' = ($ApplianceName + "." + $Domain)

$jsonString = ConvertTo-Json $ConfigSpec -Depth 3
$jsonString | Out-File ($ApplianceName + ".json") -Encoding "ASCII"

Invoke-Expression ($IsoDriveLetter + ":\vcsa-cli-installer\win32\vcsa-deploy.exe $($ApplianceName + '.json')")