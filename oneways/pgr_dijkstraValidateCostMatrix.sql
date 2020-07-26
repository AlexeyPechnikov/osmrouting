-- complementary function for pgr_dijkstraSymmetrizeCostMatrix
CREATE OR REPLACE FUNCTION pgr_dijkstraValidateCostMatrix(matrix_cell_sql text,
    OUT start_vid BIGINT, OUT end_vid BIGINT, OUT agg_cost float)
RETURNS SETOF RECORD AS
$BODY$
DECLARE
    sql text;
    r record;
BEGIN
    sql := 'WITH RECURSIVE src AS (' || matrix_cell_sql || '),
    dst AS (
        select
            *
        from src where start_vid =
            (select
                start_vid
            from src
            group by start_vid
            order by count(*) desc
            limit 1)
        union
        select
            src.*
        from src, dst
        where src.start_vid=dst.end_vid
    )
    select * from dst';
    FOR r IN EXECUTE sql LOOP
        start_vid := r.start_vid;
        end_vid   := r.end_vid;
        agg_cost  := r.agg_cost;
        RETURN NEXT;
    END LOOP;
END;
$BODY$
LANGUAGE plpgsql VOLATILE STRICT;
