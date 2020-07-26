-- produce the equal symmetric matrix from asymmetric matrix returned by pgr_dijkstraCostMatrix()
CREATE OR REPLACE FUNCTION pgr_dijkstraSymmetrizeCostMatrix(matrix_cell_sql text,
    OUT start_vid BIGINT, OUT end_vid BIGINT, OUT agg_cost float)
RETURNS SETOF RECORD AS
$BODY$
DECLARE
    sql text;
    r record;
BEGIN
    sql := 'with edges as (' || matrix_cell_sql || ')
        select 3e9+start_vid as start_vid, end_vid as end_vid, agg_cost from edges
        union
        select end_vid, 3e9+start_vid, agg_cost from edges
        union
        select 3e9+start_vid, start_vid, 0 from edges
        union
        select start_vid, 3e9+start_vid, 0 from edges
        union
        select start_vid, end_vid, 1e6 from edges
        union
        select 3e9+start_vid, 3e9+end_vid, 1e6 from edges
        ';
    FOR r IN EXECUTE sql LOOP
        start_vid := r.start_vid;
        end_vid   := r.end_vid;
        agg_cost  := r.agg_cost;
        RETURN NEXT;
    END LOOP;
END;
$BODY$
LANGUAGE plpgsql VOLATILE STRICT;
