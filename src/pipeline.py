"""Torsdagsopgave: implementér en reproducerbar batch-pipeline.

Mandag til onsdag køres SQL-filerne enkeltvis med run_sql_file.py.
Denne fil skal først kunne køre, når du implementerer torsdagens opgave.
"""

from pathlib import Path
import duckdb

DB_PATH = Path("data/warehouse/taxi_20556.duckdb")

SQL_FILES = [
    Path("sql/02_dimensions.sql"),
    Path("sql/03_fact_trip.sql"),
    Path("sql/04_aggregates.sql"),
]

# Kilder:
# Python pathlib:
# https://docs.python.org/3/library/pathlib.html
#
# DuckDB Python API:
# https://duckdb.org/docs/stable/clients/python/overview


def read_sql_file(path: Path) -> str:
    """Læs en SQL-fil og kontroller, at den indeholder SQL."""

    if not path.exists():
        raise FileNotFoundError(f"SQL-fil mangler: {path}")

    sql = path.read_text(encoding="utf-8")

    sql_without_comments = "\n".join(
        line for line in sql.splitlines()
        if not line.strip().startswith("--")
    ).strip()

    if not sql_without_comments:
        raise ValueError(f"SQL-filen indeholder ingen SQL: {path}")

    return sql


def main() -> None:
    """Byg den analytiske løsning i den rækkefølge, afhængighederne kræver."""
            # TODO: Implementér torsdagens pipeline.
            #
            # Krav:
            # - Kør dimensions-, fact- og aggregate-trinnene i en begrundet rækkefølge.
            # - Stop tydeligt, hvis en påkrævet SQL-fil mangler eller ikke indeholder SQL.
            # - Brug den lokale DuckDB-database på DB_PATH.
            # - Luk databaseforbindelsen, også hvis et trin fejler.
            # - Vis hvilket trin der kører, så en fejl kan placeres.
            # - En ny kørsel må ikke fordoble de afledte data.
            #
            # Dokumentér kort de Python- og DuckDB-kilder, du bruger.

    conn = duckdb.connect(str(DB_PATH))

    try:
        print(f"Database åbnet: {DB_PATH}")

        for sql_file in SQL_FILES:
            print(f"Trin: {sql_file}")

            sql = read_sql_file(sql_file)
            conn.execute(sql)

            print(f"Færdig: {sql_file}")

        fact_count = conn.execute(
            "SELECT COUNT(*) FROM fact_trip"
        ).fetchone()[0]

        aggregate_count = conn.execute(
            "SELECT COUNT(*) FROM agg_daily_pickup_zone"
        ).fetchone()[0]

        print(f"fact_trip: {fact_count} rækker")
        print(f"agg_daily_pickup_zone: {aggregate_count} rækker")

    finally:
        conn.close()
        print("Databaseforbindelsen er lukket.")


if __name__ == "__main__":
    main()