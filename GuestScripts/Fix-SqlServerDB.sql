DECLARE @Database VARCHAR(255) 
DECLARE @cmd NVARCHAR(500)  

SET @Database = 'VCDB'

PRINT 'Reset DB status'
EXEC sp_resetstatus @Database;

PRINT 'Changing to emergency mode'
SET @cmd = 'ALTER DATABASE ' + @Database + ' SET EMERGENCY'
EXEC (@cmd)

PRINT 'Checking database'
DBCC checkdb(@Database)

PRINT 'Changing to single user mode'
SET @cmd = 'ALTER DATABASE ' + @Database + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
EXEC (@cmd)

PRINT 'Repairing DB'
DBCC CheckDB (@Database, REPAIR_ALLOW_DATA_LOSS)

PRINT 'Changing to multi user mode'
SET @cmd =  'ALTER DATABASE ' + @Database + ' SET MULTI_USER'
EXEC (@cmd)