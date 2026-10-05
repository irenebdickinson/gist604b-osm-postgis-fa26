-- Query 4: Railway Density by County
-- Purpose: Calculate railway density (km per sq km) in each county

-- Requirements:
-- - Use adminareas_a for counties (fclass = 'admin_level6')
-- - Use railways for line features
-- - Use ST_Intersects to match railways to counties
-- - Use ST_Intersection to clip railway segments to county boundaries
-- - Use ST_Length(geom::geography) for accurate railway lengths
-- - Convert meters to kilometers (divide by 1,000)
-- - Use ST_Area(geom::geography) for county area
-- - Convert square meters to square kilometers (divide by 1,000,000)
-- - Use a CTE to calculate intermediate metrics
-- - Calculate railway density = total_rail_length_km / county_area_sq_km
-- - Order results by railway density (highest first)

-- Expected Output:
-- - county_name
-- - total_rail_length_km
-- - county_area_sq_km
-- - rail_density_km_per_sq_km
-- - geom

WITH county_metrics AS (
    SELECT
        aa.name AS county_name,
        SUM(ST_Length(ST_Intersection(r.geom, aa.geom)::geography)) / 1000 AS total_rail_length_km,
        ST_Area(aa.geom::geography) / 1000000 AS county_area_sq_km,
        aa.geom
    FROM
        adminareas_a AS aa
    JOIN
        railways AS r ON ST_Intersects(aa.geom, r.geom)
    WHERE
        aa.fclass = 'admin_level6'
    GROUP BY
        aa.name, aa.geom
)

SELECT
    county_name,
    total_rail_length_km,
    county_area_sq_km,
    total_rail_length_km / county_area_sq_km AS rail_density_km_per_sq_km,
    geom
FROM
    county_metrics
ORDER BY
    rail_density_km_per_sq_km DESC;