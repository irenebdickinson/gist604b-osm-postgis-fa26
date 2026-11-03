-- Query 1: Nevada Settlements
-- Purpose: Extract named settlement points (cities, towns, villages, hamlets)
--          to show how Nevada's population is distributed across the state.

-- Requirements:
-- - Use the places layer (point features)
-- - Filter fclass to city, town, village, hamlet
-- - Return name, settlement type, population, and geometry

-- Expected Output:
-- - place_name
-- - place_type
-- - population
-- - geom

SELECT
    name       AS place_name,
    fclass     AS place_type,
    population,
    geom
FROM
    places
WHERE
    fclass IN ('city', 'town', 'village', 'hamlet')
ORDER BY
    population DESC NULLS LAST;