-- Query 5: County Amenity Synthesis
-- Purpose: Compare counties using park area, railway density, and restaurant count

-- Requirements:
-- - Use adminareas_a for counties (fclass = 'admin_level6')
-- - Use landuse_a for parks (fclass = 'park')
-- - Use railways for line features
-- - Use pois for point features
-- - Filter POIs where fclass = 'restaurant'
-- - Use multiple CTEs to calculate county area, park area, railway length, and restaurant count
-- - Use ST_Intersection to clip parks and railways to county boundaries
-- - Use ST_Area(geom::geography) for park and county area
-- - Use ST_Length(geom::geography) for railway length
-- - Convert square meters to square kilometers and meters to kilometers
-- - Use COALESCE to handle counties with missing values
-- - Use CASE to safely calculate derived metrics
-- - Order results by railway density (highest first)
-- - Include geom column for spatial visualization in GeoPandas

-- Expected Output:
-- - county_name
-- - county_area_sq_km
-- - park_area_sq_km
-- - percent_park_area
-- - total_rail_length_km
-- - rail_density_km_per_sq_km
-- - restaurant_count
-- - geom

WITH counties AS (
    SELECT
        aa.name AS county_name,
        aa.geom,
        ST_Area(aa.geom::geography) / 1000000 AS county_area_sq_km
    FROM
        adminareas_a AS aa
    WHERE
        aa.fclass = 'admin_level6'
),
park_area AS (
    SELECT
        c.county_name,
        SUM(ST_Area(ST_Intersection(l.geom, c.geom)::geography)) / 1000000 AS park_area_sq_km
    FROM
        counties AS c
    JOIN
        landuse_a AS l ON ST_Intersects(c.geom, l.geom)
    WHERE
        l.fclass = 'park'
    GROUP BY
        c.county_name
),
rail_length AS (
    SELECT
        c.county_name,
        SUM(ST_Length(ST_Intersection(r.geom, c.geom)::geography)) / 1000 AS total_rail_length_km
    FROM
        counties AS c
    JOIN
        railways AS r ON ST_Intersects(c.geom, r.geom)
    GROUP BY
        c.county_name
),
restaurant_count AS (
    SELECT
        c.county_name,
        COUNT(*) AS restaurant_count
    FROM
        counties AS c
    JOIN
        pois AS p ON ST_Intersects(c.geom, p.geom)
    WHERE
        p.fclass = 'restaurant'
    GROUP BY
        c.county_name
)
SELECT
    c.county_name,
    c.county_area_sq_km,
    COALESCE(p.park_area_sq_km, 0) AS park_area_sq_km,
    CASE
        WHEN c.county_area_sq_km > 0 THEN
            (COALESCE(p.park_area_sq_km, 0) / c.county_area_sq_km) * 100
        ELSE 0
    END AS percent_park_area,
    COALESCE(r.total_rail_length_km, 0) AS total_rail_length_km,
    CASE
        WHEN c.county_area_sq_km > 0 THEN
            COALESCE(r.total_rail_length_km, 0) / c.county_area_sq_km
        ELSE 0
    END AS rail_density_km_per_sq_km,
    COALESCE(rc.restaurant_count, 0) AS restaurant_count,
    c.geom
FROM
    counties AS c
LEFT JOIN
    park_area AS p ON c.county_name = p.county_name
LEFT JOIN
    rail_length AS r ON c.county_name = r.county_name
LEFT JOIN
    restaurant_count AS rc ON c.county_name = rc.county_name
ORDER BY
    rail_density_km_per_sq_km DESC;