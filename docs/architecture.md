# Arkitektur

Version 1.0 · Elevskabelon

## Indhold

1. [Data](#data)
2. [Analysebehov](#analysebehov)
3. [Arkitekturskitse](#arkitekturskitse)

## Data

Yellow Taxi: Én rå række ser ud til at repræsentere:

> Én taxatur. Rækken viser blandt andet, hvornår turen starter og slutter, hvor den starter og slutter, turens distance, antal passagerer og prisen på turen.

Taxi Zone Lookup: Én række repræsenterer:

> Én taxi-zone. Hver zone har et LocationID, borough, zone-navn og service_zone.

Relevante felter:

- tpep_pickup_datetime: Dato og tidspunkt for hvornår turen starter.
- tpep_dropoff_datetime: Dato og tidspunkt for hvornår turen slutter.
- PULocationID: ID på den zone hvor turen starter.
- DOLocationID: ID på den zone hvor turen slutter.
- trip_distance: Hvor langt taxaturen er kørt. Det måles i miles.

Kilde:
NYC Taxi & Limousine Commission, Yellow Taxi Trip Records Data Dictionary:
https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf

Jeg fandt også noget i dataene, som jeg ikke forventede. Pickup-tiderne går fra 31-12-2024 20:47:55 til 01-02-2025 00:00:44, selv om filen hedder yellow_tripdata_2025-01.parquet.

Jeg ændrer ikke de rå data på grund af det. Jeg beholder dem som de er og noterer bare det, jeg har fundet.

## Analysebehov

1. Hvilke pickup-zoner har flest taxature?

2. Hvilke pickup-zoner har den højeste gennemsnitlige pris pr. tur?

3. Hvordan ændrer antallet af taxature sig fra dag til dag?

Alle tre spørgsmål kan undersøges med de data, vi har. De to første bruger Taxi Zone Lookup, så LocationID kan kobles sammen med et rigtigt zone-navn.

## Arkitekturskitse

Yellow Taxi ──→ Parquet ──┐
                          ├──→ data/raw
Zone Lookup ──→ CSV ──────┘
                              ↓
                           DuckDB
                              ↓
                      SQL undersøgelse
                              ↓
                      Join LocationID
                              ↓
                         Datamodel
                         ↙       ↘
                    Fact Trip   Dimensioner
                         ↘       ↙
                         Aggregater
                              ↓
                    Analyser/resultater


Dataflowet starter med de to filer Yellow Taxi og Taxi Zone Lookup. De bliver gemt i data/raw, og jeg beholder dem uændret.

DuckDB læser filerne direkte fra raw-mappen. Her kan jeg undersøge data med SQL, for eksempel antal rækker, datoer, zoner og priser. Jeg kan også koble taxadata sammen med Zone Lookup.

Det, der virker nu, er raw-data, DuckDB, SQL-undersøgelsen, datamodellen og aggregatet.

Datamodellen består af dim_date, dim_zone og fact_trip. Derefter er der bygget et aggregate, som samler data pr. pickup-zone og dato.

Raw-data er de originale filer. Datamodellen, joins, beregninger og aggregater er afledte data, fordi de bliver lavet ud fra raw-data.

Kilder:
NYC Taxi & Limousine Commission, Trip Record Data:
https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

NYC Taxi & Limousine Commission, Yellow Taxi Data Dictionary:
https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf

DuckDB dokumentation:
https://duckdb.org/docs/stable/

## Dag03 – aggregate, lagring og genskabelse

### Aggregate

I fact_trip repræsenterer én række én taxatur.

I agg_daily_pickup_zone repræsenterer én række én pickup-zone på én dato.

Aggregatet bevarer dato, pickup-zone, antal ture og afstandsgrundlaget.
Det gør det muligt at beregne gennemsnitlig trip_distance igen.

Fact-tabellen har 3.475.226 rækker, mens aggregatet har 7.308 rækker.
Kontrollen viser, at summen af antal_ture i aggregatet stadig er 3.475.226.

Aggregatet kan f.eks. bruges til at undersøge den gennemsnitlige afstand
pr. pickup-zone og dato.

Hvis jeg vil undersøge en bestemt taxatur, skal jeg bruge fact_trip,
fordi detaljerne om den enkelte tur går tabt i aggregatet.

### NULL og nul

Der er 0 NULL-værdier i trip_distance, men 90.893 ture har værdien 0.

NULL betyder, at værdien mangler eller er ukendt.
0 betyder, at der faktisk er registreret værdien 0.
Derfor er NULL og 0 ikke det samme.

### Lagring og platform

Raw-data ligger i data/raw som Parquet og CSV.

De afledte tabeller dim_date, dim_zone, fact_trip og
agg_daily_pickup_zone gemmes i DuckDB-databasen:

data/warehouse/taxi_20556.duckdb

Jeg bruger DuckDB, fordi det passer godt til en lokal analytisk løsning.
DuckDB kan læse Parquet og CSV direkte og kan bruges til SQL-analyser.

En begrænsning er, at vores løsning er lokal og ikke i sig selv er
en komplet cloud- eller enterprise-platform.

Et relevant alternativ kunne være PostgreSQL, hvis løsningen skulle køre
på en central server og bruges af flere brugere eller applikationer.

Til dette projekt vælger jeg stadig DuckDB, fordi løsningen er lokal,
analytisk og arbejder med batch-data.

Raw-mappen kan sammenlignes med idéen om at bevare rå data i en data lake,
men en lokal mappe er ikke i sig selv en komplet data lake.

### Genskabelse

For at kunne genskabe løsningen skal raw-data og koden bevares.

Vigtige dele er:

- data/raw/yellow_tripdata_2025-01.parquet
- data/raw/taxi_zone_lookup.csv
- SQL-filerne
- src/pipeline.py
- requirements.txt

Hvis DuckDB-databasen bliver slettet, kan de afledte tabeller bygges igen
fra raw-data ved hjælp af SQL-filerne og pipelinen.

Git bruges til versionering af kode, men Git-historikken er ikke i sig selv
en backup af raw-data.

En checksum kan bruges til at kontrollere, om en fil er den samme,
men en checksum indeholder ikke selve dataene og kan derfor ikke erstatte
en backup.

### Datalivscyklus

Persistent state er data, som bliver gemt, så de stadig findes efter et program
eller en pipeline er stoppet. I projektet er raw-filerne og DuckDB-databasefilen
eksempler på persistent state.

Retention handler om, hvor længe data og forskellige versioner skal bevares.
Raw-data bør bevares, hvis et tidligere resultat senere skal kunne genskabes.

Et snapshot er en kopi af data eller systemets tilstand på et bestemt tidspunkt.
Det kan bruges til at gå tilbage til en tidligere tilstand, men et snapshot er
ikke det samme som de originale raw-data.

En backup er en separat kopi, som kan bruges, hvis de normale data går tabt.
Git bruges til versionering af kode, men er ikke en backup af Taxi-dataene.

Rebuild betyder, at de afledte tabeller bliver bygget igen fra raw-data og kode.
Det er derfor ikke det samme som at gendanne en database fra en backup.

## Dag04 – processing og pipeline

### Batch-pipeline

Jeg har lavet en batch-pipeline i Python, som bygger de afledte tabeller i
den rækkefølge, de er afhængige af:

02_dimensions.sql
→ 03_fact_trip.sql
→ 04_aggregates.sql

01_explore.sql er ikke med i pipelinen, fordi den bruges til at undersøge
data og ikke til at bygge modellen.

Pipelinen bruger DuckDBs parser til at læse SQL-filerne. Før builden starter,
kontrollerer den, at alle SQL-filer findes og indeholder SQL-statements.

### Fejl, transaction og rollback

Hele builden køres i én transaction.

Hvis alle trin lykkes, laver pipelinen COMMIT, og ændringerne bliver gemt.

Hvis et statement fejler, stopper pipelinen. De næste statements og trin
bliver ikke kørt, og der bliver lavet ROLLBACK. På den måde bliver databasen
ikke efterladt med en halv build.

Pipelinen viser både trin og statement-nummer, så det er muligt at se,
hvor en fejl opstår.

Jeg testede dette med en ufarlig fejl. Statement 1 lavede en testtabel,
statement 2 fejlede med vilje, og statement 3 blev ikke kørt.
Efter ROLLBACK kontrollerede jeg databasen, og testtabellen fra statement 1
var også væk.

### Genkørsel

Jeg har kørt pipelinen to gange med det samme input.

Begge kørsler gav:

- fact_trip: 3.475.226 rækker
- agg_daily_pickup_zone: 7.308 rækker

Data blev derfor ikke fordoblet.

Det virker, fordi de afledte tabeller bygges igen med CREATE OR REPLACE TABLE
i stedet for at lægge de samme rækker oven i de gamle.

Et nyt månedligt batch er noget andet end at genkøre det samme input.
Den nuværende løsning er lavet og testet med januar-filen. Hvis flere måneder
skal indlæses, skal pipelinen udvides til at håndtere flere inputfiler og
kontrollere blandt andet dubletter og dataversioner.

### ETL og ELT

I denne løsning bliver raw-data først gemt som Parquet og CSV i data/raw.

DuckDB læser derefter raw-data og laver dimensioner, fact-tabellen og
aggregatet. De afledte tabeller gemmes i:

data/warehouse/taxi_20556.duckdb

Løsningen minder derfor mest om ELT, fordi raw-data først er tilgængelige,
og transformationerne derefter bliver udført i DuckDB.

### Tænkt streamingvariant

Den nuværende løsning er batch. Den arbejder med en afgrænset fil og stopper,
når behandlingen er færdig.

Hvis løsningen i stedet skulle være streaming, kunne dataflowet se sådan ud:

Taxi / producer
→ queue eller log
→ processor
→ database
→ dashboard eller anden applikation

Produceren sender nye events.

En queue eller log holder events, indtil de kan behandles.

Processoren læser events og laver de nødvendige transformationer.

Databasen gemmer resultatet, og en applikation eller et dashboard kan bruge
dataene.

En orchestrator har en anden opgave. Den styrer og koordinerer jobs, for
eksempel hvornår et job skal starte, og hvad der skal ske efter et andet job.
Den laver ikke selve datatransformationen.

Streamingvarianten er kun et forslag. Den er ikke implementeret i dette
projekt.

### Parallel processing

Hvis datamængden bliver så stor, at pipelinen ikke kan blive færdig inden
for den ønskede tid, kunne arbejdet deles op.

Et eksempel kunne være:

Data
→ partitionering efter dato
→ flere workers
→ resultater kombineres
→ samlet resultat

Hver worker kan behandle sin egen dato eller periode samtidig.

Fordelen er, at store datamængder kan behandles hurtigere.
Ulempen er mere kompleksitet og ekstra arbejde med at koordinere workers
og samle resultaterne korrekt.

Parallel processing er kun et konceptuelt forslag i dette projekt og er
ikke implementeret.

### Implementeret og testet

Implementeret og testet:

- Python batch-pipeline
- rækkefølgen dimensions → fact → aggregate
- SQL parsing med DuckDB
- transaction med COMMIT og ROLLBACK
- fejltest
- genkørsel med samme input uden fordobling

Kun beskrevet som forslag:

- streaming
- queue/log
- orchestration
- parallel processing
- indlæsning af flere månedlige batches