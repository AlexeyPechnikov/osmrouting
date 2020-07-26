#!/bin/sh
set -e

DATABASE=osmrouting

psql "$DATABASE" -c "CREATE EXTENSION IF NOT EXISTS PostGIS;"
psql "$DATABASE" -c "CREATE EXTENSION IF NOT EXISTS PgRouting;"
psql "$DATABASE" -f osm_network.sql
psql "$DATABASE" -f osm_nodes.sql
psql "$DATABASE" -f osm_buildings.sql

echo "done"
