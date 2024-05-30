#!/bin/bash
duckdb -c "
ATTACH '$PGURL' AS db (TYPE POSTGRES, READ_ONLY);
COPY (select * from db.public.arcs) TO '/tmp/arcs.parquet' (FORMAT PARQUET)
"
cat /tmp/arcs.parquet
