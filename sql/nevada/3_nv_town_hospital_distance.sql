-- Query 3: Distance from Towns to the Nearest Hospital
-- Purpose: Measure how far each Nevada town and village is from its
--          nearest hospital, as an indicator of rural healthcare access.

-- Requirements:
-- - Use places for towns and villages (fclass IN ('town', 'village'))
-- - Combine hospitals from pois (points) and pois_a (polygon centroids) in a CTE
-- - Use CROSS JOIN LATERAL with the <-> operator to find the nearest hospital
-- - Use ST_Distance(geom::geography) for accurate distance in meters; convert to km
-- - Order by distance (most remote first)
-- - Include geom for mapping

-- Expected Output:
-- - town_name
-- - place_type
-- - population
-- - nearest_hospital
-- - distance_km
-- - geom

WITH hospitals AS (
    SELECT name, geom
    FROM pois
    WHERE fclass = 'hospital'

    UNION ALL

    SELECT name, ST_Centroid(geom) AS geom
    FROM pois_a
    WHERE fclass = 'hospital'
)
SELECT
    pl.name     AS town_name,
    pl.fclass   AS place_type,
    pl.population,
    h.name      AS nearest_hospital,
    ST_Distance(pl.geom::geography, h.geom::geography) / 1000 AS distance_km,
    pl.geom
FROM
    places AS pl
CROSS JOIN LATERAL (
    SELECT hs.name, hs.geom
    FROM hospitals AS hs
    ORDER BY hs.geom <-> pl.geom
    LIMIT 1
) AS h
WHERE
    pl.fclass IN ('town', 'village')
ORDER BY
    distance_km DESC;