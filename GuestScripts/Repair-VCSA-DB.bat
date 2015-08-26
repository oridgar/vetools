Su –s /bin/bash postgres –c “/opt/vmware/vpostgres/9.0/bin/pg_resetxlog /storage/db/vpostgres –f”
./pg_dump VCDB –U vc –Fp –c > vcdbbackup./reindexdb VCDB –U vc
PGPASSWORD='EMB_DB_PASSWORD' /opt/vmware/vpostgres/9.0/bin/psql -d VCDB -Upostgres -f vcdbbackup
/opt/vmware/vpostgres/9.0/bin/reindexdb VCDB –U vc