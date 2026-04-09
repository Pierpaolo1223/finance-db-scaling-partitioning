EXPLAIN (analyze, buffers)
SELECT COUNT(*) 
FROM transactions.transactions_large
WHERE created_at BETWEEN '2026-10-01' AND '2026-10-31'
  AND amount::text LIKE '%.99';