-- 20556 · Tirsdag · Version 1.0
-- TODO: Implementér fact_trip ud fra grain og modelvalg i docs/model.md.
-- Begrund dine measures og relationer til dimensionernes to roller.
-- Dokumentér, hvad din nøgle identificerer, også ved en genopbygning.

-- TODO: Skriv kontroller af relationernes dækning og kardinalitet.
-- Resultater skal vise, om rækker mangler eller mangedobles ved joins.

-- TODO: Skriv tre analysequeries nederst i denne fil.
-- De skal samlet bruge dim_date, dim_zone og mindst ét numerisk measure
-- ud over optælling. Mindst én skal besvare et analysebehov fra mandag.
-- Kontrolqueries tæller ikke som de tre analysequeries.

-- Opret fact_trip.
-- Én række i fact_trip repræsenterer én taxatur.
-- trip_id identificerer rækken i fact_trip og bliver lavet igen,
-- når tabellen genopbygges.
-- trip_distance, fare_amount, tip_amount og total_amount er measures,
-- fordi de kan bruges til beregninger som sum og gennemsnit.
-- dim_date bruges både til pickup- og dropoff-dato.
-- dim_zone bruges både til pickup- og dropoff-zone.

CREATE OR REPLACE TABLE fact_trip AS
SELECT
    ROW_NUMBER() OVER () AS trip_id,

    CAST(tpep_pickup_datetime AS DATE) AS pickup_date,
    CAST(tpep_dropoff_datetime AS DATE) AS dropoff_date,

    PULocationID AS pickup_zone_id,
    DOLocationID AS dropoff_zone_id,

    trip_distance,
    fare_amount,
    tip_amount,
    total_amount

FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- Kontroller at fact_trip har samme antal rækker som raw-data.
SELECT
    COUNT(*) AS antal_fact_rækker
FROM fact_trip;


-- Kontroller om trip_id er entydig.
SELECT
    trip_id,
    COUNT(*) AS antal
FROM fact_trip
GROUP BY trip_id
HAVING COUNT(*) > 1;
-- fact_trip har 3.475.226 rækker, som er det samme som raw-data.
-- Der er ingen dubletter i trip_id, så nøglen er entydig i fact_trip.

-- Kontroller om alle pickup-zoner findes i dim_zone.
SELECT
    COUNT(*) AS manglende_pickup_zoner
FROM fact_trip AS f
LEFT JOIN dim_zone AS z
    ON f.pickup_zone_id = z.zone_id
WHERE z.zone_id IS NULL;


-- Kontroller om alle dropoff-zoner findes i dim_zone.
SELECT
    COUNT(*) AS manglende_dropoff_zoner
FROM fact_trip AS f
LEFT JOIN dim_zone AS z
    ON f.dropoff_zone_id = z.zone_id
WHERE z.zone_id IS NULL;
-- Der mangler ingen pickup- eller dropoff-zoner i dim_zone.
-- Zone-dimensionen dækker derfor begge roller i fact_trip.

-- Kontroller om alle pickup-datoer findes i dim_date.
SELECT
    COUNT(*) AS manglende_pickup_datoer
FROM fact_trip AS f
LEFT JOIN dim_date AS d
    ON f.pickup_date = d.dato
WHERE d.dato IS NULL;


-- Kontroller om alle dropoff-datoer findes i dim_date.
SELECT
    COUNT(*) AS manglende_dropoff_datoer
FROM fact_trip AS f
LEFT JOIN dim_date AS d
    ON f.dropoff_date = d.dato
WHERE d.dato IS NULL;
-- Der mangler ingen pickup- eller dropoff-datoer i dim_date.
-- Datodimensionen dækker derfor begge roller i fact_trip.

-- Kontroller at joins til dimensionerne ikke mangedobler rækker.
SELECT
    COUNT(*) AS antal_efter_joins
FROM fact_trip AS f
LEFT JOIN dim_date AS pd
    ON f.pickup_date = pd.dato
LEFT JOIN dim_date AS dd
    ON f.dropoff_date = dd.dato
LEFT JOIN dim_zone AS pz
    ON f.pickup_zone_id = pz.zone_id
LEFT JOIN dim_zone AS dz
    ON f.dropoff_zone_id = dz.zone_id;
-- Der er stadig 3.475.226 rækker efter joins til dimensionerne.
-- Joins mangedobler derfor ikke rækkerne i fact_trip.

-- Analyse 1:
-- Hvilke pickup-zoner har flest taxature?
SELECT
    z.borough,
    z.zone,
    COUNT(*) AS antal_ture
FROM fact_trip AS f
JOIN dim_zone AS z
    ON f.pickup_zone_id = z.zone_id
GROUP BY
    z.borough,
    z.zone
ORDER BY antal_ture DESC
LIMIT 10;

-- Analyse 2:
-- Hvilke pickup-zoner har den højeste gennemsnitlige pris pr. tur?
-- Kun zoner med mindst 1000 ture tages med, så få ture ikke påvirker resultatet for meget.
SELECT
    z.borough,
    z.zone,
    COUNT(*) AS antal_ture,
    ROUND(AVG(f.total_amount), 2) AS gennemsnitlig_pris
FROM fact_trip AS f
JOIN dim_zone AS z
    ON f.pickup_zone_id = z.zone_id
GROUP BY
    z.borough,
    z.zone
HAVING COUNT(*) >= 1000
ORDER BY gennemsnitlig_pris DESC
LIMIT 10;

-- Analyse 3:
-- Hvordan ændrer antallet af taxature sig fra dag til dag?
SELECT
    d.dato,
    COUNT(*) AS antal_ture
FROM fact_trip AS f
JOIN dim_date AS d
    ON f.pickup_date = d.dato
GROUP BY d.dato
ORDER BY d.dato;
