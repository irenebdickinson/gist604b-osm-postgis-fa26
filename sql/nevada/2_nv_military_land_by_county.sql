-- Query 2: Military Land by County
-- Purpose: Calculate the area and percentage of each Nevada county
--          covered by military land use.

-- Requirements:
-- - Use adminareas_a for counties (fclass = 'admin_level6')
-- - Use landuse_a for military land (fclass = 'military')
-- - ST_Union military polygons per county so overlapping polygons are not double counted
-- - Clip to county boundaries with ST_Intersection
-- - Use ::geography for accurate area in square meters; convert to sq km
-- - LEFT JOIN + COALESCE so counties with no military land show 0
-- - Include geom for mapping

-- Expected Output:
-- - county_name
-- - county_area_sq_km
-- - military_area_sq_km
-- - percent_military
-- - geom

WITH counties AS (
    SELECT
        name AS county_name,
        geom,
        ST_Area(geom::geography) / 1000000 AS county_area_sq_km
    FROM
        adminareas_a
    WHERE
        fclass = 'admin_level6'
),
military AS (
    SELECT
        c.county_name,
        ST_Area(
            ST_Intersection(ST_Union(ST_MakeValid(l.geom)), c.geom)::geography
        ) / 1000000 AS military_area_sq_km
    FROM
        counties AS c
    JOIN
        landuse_a AS l ON ST_Intersects(c.geom, l.geom)
    WHERE
        l.fclass = 'military'
    GROUP BY
        c.county_name, c.geom
)
SELECT
    c.county_name,
    c.county_area_sq_km,
    COALESCE(m.military_area_sq_km, 0) AS military_area_sq_km,
    CASE
        WHEN c.county_area_sq_km > 0
        THEN COALESCE(m.military_area_sq_km, 0) / c.county_area_sq_km * 100
        ELSE 0
    END AS percent_military,
    c.geom
FROM
    counties AS c
LEFT JOIN
    military AS m ON c.county_name = m.county_name
ORDER BY
    percent_military DESC;