-- Query 2: Park Area by County
-- Purpose: Calculate the total area of parks in each county

-- Requirements:
-- - Use adminareas_a for counties (fclass = 'admin_level6')
-- - Use landuse_a for parks (fclass = 'park')
-- - Use ST_Intersects to join parks to counties
-- - Use ST_Intersection to clip park geometries to county boundaries
-- - Use ST_Area(geom::geography) for accurate measurements on WGS84
-- - Convert square meters to square kilometers (divide by 1,000,000)
-- - Group results by county name
-- - Include geom column for spatial visualization

-- Expected Output:
-- - county_name
-- - park_area_sq_km
-- - geom

SELECT
    aa.name AS county_name,
    SUM(ST_Area(ST_Intersection(l.geom, aa.geom)::geography)) / 1000000 AS park_area_sq_km,
    aa.geom
FROM
    adminareas_a AS aa
JOIN
    landuse_a AS l ON ST_Intersects(aa.geom, l.geom)
WHERE
    aa.fclass = 'admin_level6'
    AND l.fclass = 'park'
GROUP BY
    aa.name, aa.geom
ORDER BY
    park_area_sq_km DESC;