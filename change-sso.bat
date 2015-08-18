c:
rem Register Inventory Service with an other SSO
cd "C:\program files\VMware\Infrastructure\Inventory Service\scripts"
is-change-sso.bat https://%1:7444/lookupservice/sdk "administrator@vsphere.local" "%2"
net stop vimQueryService
net start vimQueryService

rem Register vCenter with an other SSO
cd "C:\Program Files\VMware\Infrastructure\VirtualCenter Server\ssoregtool"
#unzip sso_svccfg.zip
pause
cd sso_svccfg
repoint.cmd configure-vc --lookup-server https://%1:7444/lookupservice/sdk --user "administrator@vSphere.local" --password "%2" --openssl-path "C:\Program Files\VMware\Infrastructure\Inventory Service\bin/"
net stop vctomcat
net stop vpxd
net start vpxd
net start vctomcat

rem Web Client with an other SSO
C:\Program Files\VMware\Infrastructure\vSphereWebClient\scripts
client-repoint.bat https://%1:7444/lookupservice/sdk "administrator@vSphere.local" "%2"