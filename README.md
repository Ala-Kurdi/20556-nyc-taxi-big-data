# 20556 – NYC Taxi Big Data

Dette projekt er lavet i faget **20556 – Big Data modeller og datamodellering**.

Projektet bruger NYC Yellow Taxi-data fra januar 2025 og Taxi Zone Lookup.

Målet er at gå fra raw-data til en datamodel, aggregater, analyse og en simpel visualisering.

## Dataflow

```text
Yellow Taxi Parquet + Zone Lookup CSV
                ↓
             data/raw
                ↓
              DuckDB
                ↓
       dim_date + dim_zone
                ↓
             fact_trip
                ↓
    agg_daily_pickup_zone
                ↓
          Dag05 analyse
                ↓
           Matplotlib
                ↓
       PNG-visualisering
```

Raw-filerne bliver ikke ændret.

## Projektets mapper

```text
data/raw/        originale inputfiler
data/warehouse/  DuckDB-database
sql/             SQL til udforskning, model, aggregater og analyse
src/             Python-scripts og pipeline
docs/            arkitektur og datamodel
output/          visualisering
```

## Installation

Projektet bruger Python og pakkerne i `requirements.txt`.

På Windows:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Data kan hentes med:

```powershell
.\.venv\Scripts\python.exe src\download_data.py
```

Setup kan kontrolleres med:

```powershell
.\.venv\Scripts\python.exe src\check_setup.py
```

## SQL-filer

Projektet bruger disse SQL-filer:

```text
01_explore.sql       undersøgelse af raw-data
02_dimensions.sql    bygger dim_date og dim_zone
03_fact_trip.sql     bygger fact_trip
04_aggregates.sql    bygger agg_daily_pickup_zone
05_analysis.sql      Dag05 analyse
```

`fact_trip` har grain:

> Én række repræsenterer én taxatur.

`agg_daily_pickup_zone` har grain:

> Én række repræsenterer én pickup-zone på én dato.

## Batch-pipeline

Den reproducerbare batch-pipeline køres med:

```powershell
.\.venv\Scripts\python.exe src\pipeline.py
```

Pipelinen bygger tabellerne i denne rækkefølge:

```text
02_dimensions.sql
        ↓
03_fact_trip.sql
        ↓
04_aggregates.sql
```

`01_explore.sql` er ikke en del af builden, fordi den bruges til at undersøge data.

Pipelinen bruger en transaction. Hvis alle trin virker, bliver ændringerne gemt med COMMIT. Hvis et statement fejler, stopper pipelinen og laver ROLLBACK.

Pipelinen er testet med samme input flere gange uden at fordoble data.

Slutkontrollen gav:

```text
fact_trip: 3.475.226 rækker
agg_daily_pickup_zone: 7.308 rækker
```

## Dag05 – analyse

Mit spørgsmål er:

> **Hvordan ændrer antallet af taxature sig fra dag til dag?**

Analysen køres med:

```powershell
.\.venv\Scripts\python.exe src\run_sql_file.py sql\05_analysis.sql
```

Analysen bruger aggregatet og summerer `antal_ture` for alle pickup-zoner på samme dato.

Jeg filtrerer til januar 2025, fordi raw-data også indeholder enkelte datoer uden for januar.

## Visualisering

Grafen laves med:

```powershell
.\.venv\Scripts\python.exe src\visualize.py
```

Resultatet gemmes som:

```text
output/taxature_pr_dag_januar_2025.png
```

Grafen viser, at antallet af taxature ændrer sig en del fra dag til dag i januar 2025.

En begrænsning er, at dataene viser **hvad** der sker med antallet af ture, men ikke **hvorfor** antallet stiger eller falder. Det kræver andre data, hvis årsagerne skal undersøges.

## Dokumentation

Mere information om dataflow, storage, batch, ELT, rollback, streaming og parallel processing findes i:

```text
docs/architecture.md
```

Datamodellen og grain, measures og dimensions findes i:

```text
docs/model.md
```