DROP TABLE IF EXISTS routeinput;
CREATE UNLOGGED TABLE routeinput AS
select
    src.the_geom
from osm_buildings as src
limit 330
;
DROP TABLE IF EXISTS routesrc;
CREATE UNLOGGED TABLE routesrc AS
SELECT
    id,
    start_id as source,
    end_id as target,
    case when (type='osmreverse' and oneway) then 1000000 else length end as cost,
    case when type ilike 'osm%' then 1000000 else length end as reverse_cost,
    osm_network.the_geom -- for debug visualization only
FROM osm_network, (select st_collect(the_geom) as the_geom from routeinput) as t
WHERE ST_DWithin(osm_network.the_geom,t.the_geom,5e-3)
;

DROP TABLE IF EXISTS route;
CREATE UNLOGGED TABLE route as
with route_order as (
SELECT * FROM pgr_TSP(
    $$
    SELECT * FROM pgr_dijkstraSymmetrizeCostMatrix(
        $_$
        SELECT * FROM pgr_dijkstraValidateCostMatrix(
            $__$
            SELECT * FROM pgr_dijkstraCostMatrix(
                $___$
                    SELECT * FROM routesrc
                $___$,
                (select array_agg(id)
                    from (
                        select n.id
                        from osm_nodes as n, routeinput as src
                        where n.the_geom && src.the_geom
                        --and exists (select 1 from x where the_geom && n.the_geom)
                    ) as t
                ),
                directed := true
            )
            $__$
        )
        $_$
    )
    $$,
    -- parameters for MacOS version only
    tries_per_temperature := 500000,
    max_changes_per_temperature := 100000,
    randomize := false
)
),
route as (
    SELECT
        seq,path_id,path_seq,start_vid,end_vid,node,CASE WHEN end_vid=node THEN NULL ELSE edge END as edge,cost,agg_cost,route_agg_cost
    FROM pgr_dijkstraVia(
        'SELECT * FROM routesrc',
        (select array_agg(node order by seq) from route_order where node<1e9),
        directed := true
    )
),
edges as (
    select
        path_id as seq,
        start_vid as node,
        round(sum(st_length(the_geom::geography))) as length,
        st_union(the_geom) as route
    from route as r, osm_network as n
    where r.edge=n.id
    group by 1, 2
),
export as (
    select
        src.the_geom,
        r.route,
        COALESCE(length,0) as length,
        COALESCE(r.seq,0) as sequence,
        CASE WHEN r.node IS NULL THEN 'fail' ELSE 'ok' END as status
    from routeinput as src
    left join osm_nodes as n on n.the_geom && src.the_geom
    left join edges as r on r.node=n.id
    order by r.seq
)
select * from export
;
