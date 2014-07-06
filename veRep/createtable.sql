Create table OrgResource (
id serial PRIMARY KEY,
ram varchar (20) NOT NULL,
cpu varchar (20) NOT NULL,
vm  varchar (20) NOT NULL,
storage varchar (20) NOT NULL,
date date NOT NULL);

drop table dbo.PowerOffDetails;
create table dbo.PowerOffDetails (
VMuuid varchar(50) PRIMARY KEY,
Owner varchar(50),
VMName varchar(50),
vAppName varchar(50),
vAppuuid varchar(50),
OrgName varchar(50),
Date    varchar(50),
LastLogin varchar(50),
actionExecuter varchar(50));