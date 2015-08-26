rem 1.	Moving aside the current database files folder
rem 2.	Create a new DB – createdb.bat
rem 3.	Re-Register Inventory Service – register-is.bat [vCenter Server URL] [Inventory Service URL] [SSO Lookup Services URL]
rem C:\Program Files\VMware\Infrastructure\VirtualCenter Server\isregtool\register-is.bat [vCenter Server URL] [Inventory Service URL] [SSO Lookup Services URL] 
rem http://kb.vmware.com/selfservice/search.do?cmd=displayKC&docType=kc&docTypeID=DT_KB_1_1&externalId=2042200


rem Get-Service -Name "vimQueryService" | Stop-Service

rem backup xdb.bootstrap file header
type "C:\Program Files\VMware\Infrastructure\Inventory Service\data\xdb.bootstrap"|findstr "<server" > "C:\Program Files\VMware\Infrastructure\Inventory Service\datahash1234321.txt"
rem FOR POWERSHELL
rem Get-Content 'C:\Program Files\VMware\Infrastructure\Inventory Service\data\xdb.bootstrap' | Select-String -pattern "<server" | ForEach-Object { $_.line } | Out-File 'C:\Program Files\VMware\Infrastructure\Inventory Service\datahash1234321.txt'


ren "C:\Program Files\VMware\Infrastructure\Inventory Service\data" "C:\Program Files\VMware\Infrastructure\Inventory Service\data.old"


cd C:\Program Files\VMware\Infrastructure\Inventory Service\scripts
createDB.bat
rem FOR POWERSHELL
rem Start-Process "C:\Program Files\VMware\Infrastructure\Inventory Service\scripts\createDB.bat"

rem replace "<server " line with the original
rem backup is at "C:\Program Files\VMware\Infrastructure\Inventory Service\datahash1234321.txt"

rem start inventory service

rem reregister with vc
cd C:\Program Files\VMware\Infrastructure\VirtualCenter Server\isregtool
register-is.bat https://<FQDN of the server>:443/sdk https://<FQDN of the server>:10443 https://<FQDN of the server>:7444/lookupservice/sdk

rem restart vCenter Server service
rem FOR POWERSHELL
rem Get-Service -Name "vimQueryService" | Start-Service