#!/bin/sh
set -e

DATABASE=osmrouting

psql "$DATABASE" -c "CREATE EXTENSION IF NOT EXISTS PostGIS;"
psql "$DATABASE" -c "CREATE EXTENSION IF NOT EXISTS PgRouting;"
psql "$DATABASE" -f ../basic/osm_network.sql
psql "$DATABASE" -f ../basic/osm_nodes.sql
psql "$DATABASE" -f ../basic/osm_buildings.sql

psql "$DATABASE" -f pgr_dijkstraSymmetrizeCostMatrix.sql
psql "$DATABASE" -f pgr_dijkstraValidateCostMatrix.sql

psql "$DATABASE" -c "
update osm_network set start_id=start_id-(select min(id) from osm_nodes),end_id=end_id-(select min(id) from osm_nodes);
update osm_nodes set id=id-(select min(id) from osm_nodes);
"

echo "done"
