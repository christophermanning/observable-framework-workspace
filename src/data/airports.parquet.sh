#!/bin/bash
duckdb -c "
ATTACH '$PGURL' AS db (TYPE POSTGRES, READ_ONLY);
COPY (select * from db.public.airports) TO '/tmp/airports.parquet' (FORMAT PARQUET)
"
cat /tmp/airports.parquet
