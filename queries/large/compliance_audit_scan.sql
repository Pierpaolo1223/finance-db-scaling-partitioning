EXPLAIN (analyze, buffers)
SELECT COUNT(*) 
FROM transactions.transactions_large
WHERE created_at >= '2026-10-01' AND created_at < '2026-11-01'
  AND (amount % 1) = 0.99;
