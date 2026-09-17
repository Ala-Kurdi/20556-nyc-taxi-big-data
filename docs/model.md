# Datamodel

**Version 1.0 · Elevskabelon**

## Indhold

1. [Grain](#grain)
2. [Modelvalg](#modelvalg)
3. [Modeldiagram](#modeldiagram)
4. [Forklaring](#forklaring)

## Grain

> Én række i `fact_trip` repræsenterer en taxatur.

## Modelvalg

**Vigtigste measures:**  
- trip_distance: Hvor langt turen er kørt.
- fare_amount: Prisen for selve taxaturen.
- tip_amount: Hvor meget der er givet i drikkepenge.
- total_amount: Det samlede beløb for turen.

**Vigtigste dimensions:**  
- Dato: Bruges til at undersøge taxature over tid.
- Zone: Bruges til at undersøge, hvor taxaturen starter og slutter.

## Modeldiagram
                    dim_date
                    --------
                    PK dato
                    aar
                    maaned
                    dag
                     1   1
                     |   |
              pickup |   | dropoff
                     N   N
                    fact_trip
                    ---------
                    PK trip_id
                    FK pickup_date
                    FK dropoff_date
                    FK pickup_zone_id
                    FK dropoff_zone_id
                    trip_distance
                    fare_amount
                    tip_amount
                    total_amount
                     N       N
                     |       |
              pickup |       | dropoff
                     1       1
                      \     /
                       \   /
                      dim_zone
                      --------
                      PK zone_id
                      borough
                      zone
                      service_zone

## Forklaring

Begrund grain, valgte measures og dimensioner ud fra analysebehovene. Forklar dimensionernes roller, og vis hvordan du kontrollerer modellens relationer. Angiv de kilder, du har anvendt.

> Jeg har valgt én taxatur som grain, fordi jeg gerne vil kunne undersøge hver tur og bagefter samle turene efter dato eller zone.
>
> Jeg har valgt trip_distance, fare_amount, tip_amount og total_amount som measures, fordi de indeholder værdier, som kan bruges til beregninger som sum og gennemsnit.
>
> Dato-dimensionen bruges til at undersøge turene over tid. Zone-dimensionen bruges både som pickup-zone og dropoff-zone. Det er den samme zone-dimension, men den har to forskellige roller.
>
> Relationerne er 1:N. Det betyder for eksempel, at én zone kan være knyttet til mange taxature. Jeg kontrollerer relationerne med SQL ved at se efter manglende matches og kontrollere, at joins ikke laver ekstra rækker. Kontrollen viste ingen manglende matches, og antal rækker var stadig 3.475.226 efter joins.
>
> Kilder:
> NYC Taxi & Limousine Commission, Yellow Taxi Trip Records Data Dictionary:
> https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf
>
> DuckDB dokumentation:
> https://duckdb.org/docs/stable/