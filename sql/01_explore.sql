-- 20556 · Mandag · Version 1.0
-- Skriv selv dine queries. Find syntaks i DuckDB-dokumentationen.
-- Gem filen, og kør den med src/run_sql_file.py fra projektets rod.


-- =========================================================
-- 1. Dataundersøgelse
-- =========================================================

-- TODO: Undersøg antal rækker, schema/datatyper, et lille udsnit,
-- perioden i pickup-tidsstemplet og forskellige pickup-lokationer.
-- Kommentér kort, hvad resultaterne fortæller, og hvad der undrer dig.


-- Hvor mange rækker er der i den rå taxi-fil?
SELECT COUNT(*) AS antal_raekker
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- Resultatet viser, at den rå taxi-fil indeholder 3.475.226 rækker.
-- Jeg undersøger videre, hvad én række præcist repræsenterer.


-- Undersøg schema og datatyper i den rå taxi-fil.
DESCRIBE
SELECT *
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');


-- Vis et lille udsnit af de rå data.
SELECT *
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
LIMIT 5;


-- Undersøg perioden i pickup-tidsstemplet.
SELECT
    MIN(tpep_pickup_datetime) AS foerste_pickup,
    MAX(tpep_pickup_datetime) AS sidste_pickup
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- Pickup-tiderne går fra 31-12-2024 til 01-02-2025.
-- Det undrer mig, fordi filen er navngivet som januar 2025.
-- Jeg ændrer ikke de rå data, men beholder observationen til den videre analyse.


-- Undersøg hvor mange forskellige pickup-lokationer der findes.
SELECT
    COUNT(DISTINCT PULocationID) AS antal_pickup_lokationer
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- Der findes 261 forskellige pickup-lokationer i datasættet.



-- =========================================================
-- 2. Eget analysespørgsmål
-- =========================================================

-- TODO: Skriv en selvvalgt gruppering, der undersøger et relevant spørgsmål.
-- Forklar i en kommentar, hvad én række i resultatet repræsenterer.

-- Hvilke pickup-zoner har den højeste gennemsnitlige total_amount?
-- Én række i resultatet repræsenterer én pickup-zone med antal ture
-- og den gennemsnitlige total_amount for ture fra zonen.

SELECT
    t.PULocationID,
    z.Borough,
    z.Zone,
    COUNT(*) AS antal_ture,
    AVG(t.total_amount) AS gennemsnit_total_amount
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') AS t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') AS z
    ON t.PULocationID = z.LocationID
GROUP BY
    t.PULocationID,
    z.Borough,
    z.Zone
ORDER BY gennemsnit_total_amount DESC
LIMIT 10;



-- =========================================================
-- 3. Sammenhæng mellem kilderne
-- =========================================================

-- TODO: Undersøg zonefilen. Begrund relationen, og skriv selv et join.
-- Vis, hvordan du kontrollerer for manglende matches og ekstra rækker.
-- Afprøv en meningsfuld ændring, og forklar dens konsekvens.
-- Join og gruppering må gerne indgå i samme query.


-- Undersøg zone lookup-filen.
SELECT *
FROM read_csv_auto('data/raw/taxi_zone_lookup.csv')
LIMIT 10;


-- PULocationID i taxidata kobles til LocationID i zone lookup.
-- På den måde kan et numerisk location-ID kobles til Borough og Zone.

SELECT
    t.PULocationID,
    z.Borough,
    z.Zone,
    COUNT(*) AS antal_ture
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') AS t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') AS z
    ON t.PULocationID = z.LocationID
GROUP BY
    t.PULocationID,
    z.Borough,
    z.Zone
ORDER BY antal_ture DESC
LIMIT 10;


-- Kontroller om nogle pickup-lokationer mangler et match i zone lookup.
SELECT
    COUNT(*) AS antal_rækker_uden_match,
    COUNT(DISTINCT t.PULocationID) AS antal_lokationer_uden_match
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') AS t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') AS z
    ON t.PULocationID = z.LocationID
WHERE z.LocationID IS NULL;

-- Resultatet er 0 rækker og 0 lokationer uden match.


-- Kontroller om joinet skaber ekstra rækker.
SELECT
    COUNT(*) AS antal_raekker_efter_join
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') AS t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') AS z
    ON t.PULocationID = z.LocationID;

-- Antallet af rækker er stadig 3.475.226 efter joinet.
-- Joinet skaber derfor ikke ekstra rækker.
-- Det tyder på, at hver pickup-location matcher højst én række i zone lookup.


-- Meningsfuld ændring:
-- Jeg medtager kun pickup-zoner med mindst 1.000 ture,
-- så gennemsnittet ikke bygger på meget få observationer.

SELECT
    t.PULocationID,
    z.Borough,
    z.Zone,
    COUNT(*) AS antal_ture,
    AVG(t.total_amount) AS gennemsnit_total_amount
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') AS t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') AS z
    ON t.PULocationID = z.LocationID
GROUP BY
    t.PULocationID,
    z.Borough,
    z.Zone
HAVING COUNT(*) >= 1000
ORDER BY gennemsnit_total_amount DESC
LIMIT 10;

-- Efter ændringen forsvinder zoner med kun få ture fra toppen.
-- Resultatet bliver derfor mere sammenligneligt, fordi hver zone nu har
-- mindst 1.000 observationer. Grænsen på 1.000 er dog et valg i analysen.



-- =========================================================
-- 4. Dokumentation
-- =========================================================

-- TODO: Notér de manualsider, du faktisk brugte, og hvad du fandt i dem.
-- Dataforklaringer, analysebehov og eget diagram gemmes i docs/architecture.md.


-- DuckDB Parquet:
-- https://duckdb.org/docs/stable/data/parquet/overview
-- Jeg brugte siden til at forstå, hvordan en Parquet-fil kan læses
-- direkte med DuckDB, og hvordan schemaet kan undersøges.


-- DuckDB CSV:
-- https://duckdb.org/docs/stable/data/csv/overview
-- Jeg brugte siden til at forstå, hvordan DuckDB kan læse CSV-filer
-- og automatisk registrere kolonner og datatyper.


-- DuckDB GROUP BY:
-- https://duckdb.org/docs/stable/sql/query_syntax/groupby
-- Jeg brugte GROUP BY til at samle taxaturene efter pickup-zone,
-- så jeg kunne beregne antal ture og gennemsnit pr. zone.


-- DuckDB HAVING:
-- https://duckdb.org/docs/stable/sql/query_syntax/having
-- Jeg brugte HAVING til at filtrere de grupperede resultater,
-- så analysen kun viser pickup-zoner med mindst 1.000 ture.