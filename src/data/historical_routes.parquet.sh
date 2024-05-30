#!/bin/bash
duckdb -c "
ATTACH '$PGURL' AS db (TYPE POSTGRES, READ_ONLY);
COPY (select * from db.public.historical_routes) TO '/tmp/historical_routes.parquet' (FORMAT PARQUET)
"
cat /tmp/historical_routes.parquet
