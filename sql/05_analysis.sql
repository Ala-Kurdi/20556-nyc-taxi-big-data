-- Dag05 analyse
-- Spørgsmål:
-- Hvordan ændrer antallet af taxature sig fra dag til dag?

SELECT
    dato,
    SUM(antal_ture) AS antal_ture
FROM agg_daily_pickup_zone
WHERE dato >= DATE '2025-01-01'
  AND dato < DATE '2025-02-01'
GROUP BY dato
ORDER BY dato;