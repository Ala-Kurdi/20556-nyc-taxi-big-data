-- 20556 · Tirsdag · Version 1.0
-- TODO: Implementér dim_zone og dim_date ud fra din dokumenterede model.
-- Dimensionerne skal kunne bruges til både pickup og dropoff.
-- Begrund nøgler og attributter. Undersøg, om nøglerne er entydige,
-- og om datodimensionen dækker begge roller i de faktiske data.
-- Bevar raw-input uændret. Skriv selv SQL og relevante kontroller.


-- Opret dim_zone fra Taxi Zone Lookup.
-- zone_id bruges som nøgle, fordi den kobler taxadata til den rigtige zone.
-- borough, zone og service_zone bruges til at beskrive zonen i analyser.
CREATE OR REPLACE TABLE dim_zone AS
SELECT
    LocationID AS zone_id,
    Borough AS borough,
    Zone AS zone,
    service_zone
FROM read_csv_auto('data/raw/taxi_zone_lookup.csv');

-- Kontroller om zone_id er entydig.
SELECT
    zone_id,
    COUNT(*) AS antal
FROM dim_zone
GROUP BY zone_id
HAVING COUNT(*) > 1;

-- Kontrollen viser ingen dubletter i zone_id.
-- Derfor kan zone_id bruges som entydig nøgle i dim_zone.

-- Opret dim_date ud fra både pickup- og dropoff-datoer.
-- dato bruges som nøgle i dim_date.
-- aar, maaned og dag gør det muligt at analysere taxaturene over tid.
CREATE OR REPLACE TABLE dim_date AS
SELECT
    dato,
    YEAR(dato) AS aar,
    MONTH(dato) AS maaned,
    DAY(dato) AS dag
FROM (
    SELECT CAST(tpep_pickup_datetime AS DATE) AS dato
    FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')

    UNION

    SELECT CAST(tpep_dropoff_datetime AS DATE) AS dato
    FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
)
ORDER BY dato;

-- Kontroller dim_date.
SELECT
    COUNT(*) AS antal_datoer,
    MIN(dato) AS foerste_dato,
    MAX(dato) AS sidste_dato
FROM dim_date;


-- Kontroller om dim_date dækker alle pickup-datoer.
SELECT
    COUNT(*) AS manglende_pickup_datoer
FROM (
    SELECT DISTINCT CAST(tpep_pickup_datetime AS DATE) AS dato
    FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
) AS p
LEFT JOIN dim_date AS d
    ON p.dato = d.dato
WHERE d.dato IS NULL;


-- Kontroller om dim_date dækker alle dropoff-datoer.
SELECT
    COUNT(*) AS manglende_dropoff_datoer
FROM (
    SELECT DISTINCT CAST(tpep_dropoff_datetime AS DATE) AS dato
    FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
) AS dr
LEFT JOIN dim_date AS d
    ON dr.dato = d.dato
WHERE d.dato IS NULL;
-- Der mangler ingen pickup- eller dropoff-datoer i dim_date.
-- Dimensionen kan derfor bruges til begge roller.
-- dim_date indeholder 34 forskellige datoer fra 18-12-2024 til 01-02-2025.