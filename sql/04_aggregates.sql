-- 20556 · Onsdag · Version 1.0
-- TODO: Byg et relevant aggregate ud fra den analytiske model.
-- Vælg og begrund grain, grupperinger og beregninger ud fra et analysebehov.
-- Vis, hvilken information der bevares, og hvilken der går tabt.
-- Undersøg, hvad der sker, hvis dit resultat aggregeres endnu en gang.

-- Analysebehov:
-- Jeg vil undersøge, hvordan antal ture og gennemsnitlig afstand
-- ændrer sig mellem pickup-zoner og datoer.

-- Grain i fact_trip:
-- Én række repræsenterer én taxatur.

-- Grain i aggregatet:
-- Én række repræsenterer én pickup-zone på én dato.

-- antal_ture viser alle ture i gruppen.
-- afstand_sum gemmer den samlede trip_distance.
-- afstand_antal viser, hvor mange ture der faktisk har en afstandsværdi.
-- De to afstandsfelter gør det muligt at beregne et korrekt gennemsnit
-- efter en yderligere aggregering.

CREATE OR REPLACE TABLE agg_daily_pickup_zone AS
SELECT
    f.pickup_date AS dato,
    f.pickup_zone_id AS zone_id,
    COUNT(*) AS antal_ture,
    SUM(f.trip_distance) AS afstand_sum,
    COUNT(f.trip_distance) AS afstand_antal
FROM fact_trip AS f
GROUP BY
    f.pickup_date,
    f.pickup_zone_id
ORDER BY
    f.pickup_date,
    f.pickup_zone_id;


-- Kontroller antal rækker før og efter aggregering.
SELECT
    (SELECT COUNT(*) FROM fact_trip) AS fact_raekker,
    (SELECT COUNT(*) FROM agg_daily_pickup_zone) AS aggregate_raekker;


-- Kontroller grain.
-- Hvis resultatet er tomt, findes hver kombination af dato og zone kun én gang.
SELECT
    dato,
    zone_id,
    COUNT(*) AS antal
FROM agg_daily_pickup_zone
GROUP BY
    dato,
    zone_id
HAVING COUNT(*) > 1;


-- Kontroller at antal ture og afstandsgrundlaget er bevaret.
SELECT
    (SELECT COUNT(*) FROM fact_trip) AS fact_antal_ture,
    (SELECT SUM(antal_ture) FROM agg_daily_pickup_zone) AS agg_antal_ture,

    (SELECT COUNT(trip_distance) FROM fact_trip) AS fact_afstand_antal,
    (SELECT SUM(afstand_antal) FROM agg_daily_pickup_zone) AS agg_afstand_antal,

    (SELECT SUM(trip_distance) FROM fact_trip) AS fact_afstand_sum,
    (SELECT SUM(afstand_sum) FROM agg_daily_pickup_zone) AS agg_afstand_sum;


-- Undersøg NULL og nul i trip_distance.
-- NULL betyder, at værdien mangler.
-- 0 betyder, at der faktisk er registreret værdien 0.
SELECT
    COUNT(*) AS antal_ture,
    COUNT(trip_distance) AS antal_med_afstand,
    COUNT(*) - COUNT(trip_distance) AS antal_null,
    SUM(CASE WHEN trip_distance = 0 THEN 1 ELSE 0 END) AS antal_nul
FROM fact_trip;


-- Vis et eksempel på den information, der er bevaret i aggregatet.
SELECT
    dato,
    zone_id,
    antal_ture,
    afstand_sum,
    afstand_antal,
    ROUND(afstand_sum / NULLIF(afstand_antal, 0), 2) AS gennemsnitlig_afstand
FROM agg_daily_pickup_zone
ORDER BY
    dato,
    zone_id
LIMIT 10;


-- Aggregatet bevarer dato, pickup-zone, antal ture og afstandsgrundlaget.
-- Detaljer om den enkelte taxatur går tabt, f.eks. trip_id,
-- dropoff-zone, fare_amount, tip_amount og den enkelte turs trip_distance.


-- Aggreger resultatet igen til én række pr. dato.
-- Det vægtede gennemsnit beregnes ud fra det bevarede afstandsgrundlag.
SELECT
    dato,
    SUM(antal_ture) AS antal_ture,
    ROUND(
        SUM(afstand_sum) / NULLIF(SUM(afstand_antal), 0),
        2
    ) AS gennemsnitlig_afstand
FROM agg_daily_pickup_zone
GROUP BY dato
ORDER BY dato;