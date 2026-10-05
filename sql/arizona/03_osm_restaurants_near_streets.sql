-- Query 3: Restaurants Near Streets
-- Purpose: Identify streets with the highest number of nearby restaurants

-- Requirements:
-- - Use roads for street features
-- - Use pois for point features
-- - Filter POIs where fclass = 'restaurant'
-- - Use ST_DWithin to find restaurants within 0.25 miles (402 meters) of streets
-- - Use a CTE to isolate restaurant locations
-- - Count the number of UNIQUE restaurants near each street (avoid double counting)
-- - Exclude streets with no name (optional but recommended)
-- - Filter to include only streets with more than 10 nearby restaurants
-- - Group by street name ONLY (aggregate geometries using ST_Union)
-- - Order results by restaurant count (highest first)
-- - Include geom column for spatial visualization in GeoPandas

-- Expected Output:
-- - street_name
-- - nearby_restaurant_count
-- - geom

WITH restaurants AS (
    SELECT
        geom
    FROM
        pois
    WHERE
        fclass = 'restaurant'
)

SELECT
    rds.name AS street_name,
    COUNT(DISTINCT r.geom) AS nearby_restaurant_count,
    ST_Union(rds.geom) AS geom
FROM
    roads AS rds
JOIN
    restaurants AS r ON ST_DWithin(r.geom::geography, rds.geom::geography, 402)
WHERE
    rds.name IS NOT NULL
    AND rds.fclass = 'cycleway'
GROUP BY
    rds.name
HAVING
    COUNT(DISTINCT r.geom) > 10
ORDER BY
    nearby_restaurant_count DESC;