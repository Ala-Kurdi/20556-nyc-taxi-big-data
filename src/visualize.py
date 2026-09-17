from pathlib import Path

import duckdb
import matplotlib.pyplot as plt


DB_PATH = Path("data/warehouse/taxi_20556.duckdb")
OUTPUT_PATH = Path("output/taxature_pr_dag_januar_2025.png")


def main() -> None:
    """Lav en graf over antal taxature pr. dag i januar 2025."""

    connection = duckdb.connect(str(DB_PATH), read_only=True)

    try:
        result = connection.execute(
            """
            SELECT
                dato,
                SUM(antal_ture) AS antal_ture
            FROM agg_daily_pickup_zone
            WHERE dato >= DATE '2025-01-01'
              AND dato < DATE '2025-02-01'
            GROUP BY dato
            ORDER BY dato
            """
        ).fetchall()

    finally:
        connection.close()

    datoer = [row[0] for row in result]
    antal_ture = [row[1] for row in result]

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    plt.figure(figsize=(10, 5))
    plt.plot(datoer, antal_ture, marker="o")
    plt.title("Antal taxature pr. dag – januar 2025")
    plt.xlabel("Dato")
    plt.ylabel("Antal taxature")
    plt.xticks(rotation=45)
    plt.grid(True)
    plt.tight_layout()

    plt.savefig(OUTPUT_PATH, dpi=150)
    plt.close()

    print(f"Graf gemt: {OUTPUT_PATH}")
    print(f"Antal dage: {len(result)}")


if __name__ == "__main__":
    main()