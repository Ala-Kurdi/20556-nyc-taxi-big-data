"""Dag04-opgave: implementér en reproducerbar batch-pipeline.

Arbejd efter Dag04 i 20556_Laerling_Ugecase_NYC_Taxi.md.
Denne fil angiver kontrakten og funktionsgrænserne, men ikke løsningen.
"""
from pathlib import Path

import duckdb


DB_PATH = Path("data/warehouse/taxi_20556.duckdb")

# 01_explore.sql er udforskning og er bevidst ikke et rebuild-trin.
STEPS = (
    ("dimensions", Path("sql/02_dimensions.sql")),
    ("fact", Path("sql/03_fact_trip.sql")),
    ("aggregate", Path("sql/04_aggregates.sql")),
)


def load_statements(
    connection: duckdb.DuckDBPyConnection, sql_path: Path
) -> list[str]:
    """Læs og parse en påkrævet SQL-fil eller stop med en tydelig fejl."""
    if not sql_path.exists():
        raise FileNotFoundError(f"SQL-fil mangler: {sql_path}")

    sql = sql_path.read_text(encoding="utf-8")

    parsed_statements = connection.extract_statements(sql)

    if not parsed_statements:
        raise ValueError(
            f"SQL-filen indeholder ingen kørbare statements: {sql_path}"
        )

    return [statement.query for statement in parsed_statements]


def run_step(
    connection: duckdb.DuckDBPyConnection,
    step_name: str,
    statements: list[str],
) -> None:
    """Kør ét trin og gør det synligt, hvor en eventuel fejl opstår."""
    print(f"\nTrin: {step_name}")

    total = len(statements)

    for index, statement in enumerate(statements, start=1):
        print(f"  Statement {index}/{total}")

        result = connection.execute(statement)

        # SELECT-statements bruges som kontroller i vores SQL-filer.
        if statement.lstrip().upper().startswith("SELECT"):
            rows = result.fetchall()

            if rows:
                for row in rows:
                    print(f"    {row}")
            else:
                print("    Ingen rækker")

    print(f"Færdig: {step_name}")


def main() -> None:
    """Kør hele builden sikkert i den rækkefølge, afhængighederne kræver."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    connection = duckdb.connect(str(DB_PATH))

    try:
        print(f"Database åbnet: {DB_PATH}")

        # Først valideres alle SQL-filer.
        parsed_steps = []

        print("\nValiderer SQL-filer...")

        for step_name, sql_path in STEPS:
            statements = load_statements(connection, sql_path)
            parsed_steps.append((step_name, statements))
            print(
                f"  OK: {sql_path} "
                f"({len(statements)} statements)"
            )

        print("Alle SQL-filer er valideret.")

        # Hele builden køres som én transaktion.
        connection.execute("BEGIN TRANSACTION")

        try:
            print("\nBuild startet.")

            for step_name, statements in parsed_steps:
                run_step(connection, step_name, statements)

            connection.execute("COMMIT")
            print("\nCOMMIT: Hele builden er gemt.")

        except Exception:
            connection.execute("ROLLBACK")
            print("\nROLLBACK: Builden fejlede. Ændringer er ikke gemt.")
            raise

        fact_count = connection.execute(
            "SELECT COUNT(*) FROM fact_trip"
        ).fetchone()[0]

        aggregate_count = connection.execute(
            "SELECT COUNT(*) FROM agg_daily_pickup_zone"
        ).fetchone()[0]

        print("\nSlutkontrol:")
        print(f"  fact_trip: {fact_count} rækker")
        print(
            "  agg_daily_pickup_zone: "
            f"{aggregate_count} rækker"
        )

        print("\nPipeline færdig uden fejl.")

    finally:
        connection.close()
        print("Databaseforbindelsen er lukket.")


if __name__ == "__main__":
    main()

