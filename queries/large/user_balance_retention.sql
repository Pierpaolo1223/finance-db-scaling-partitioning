EXPLAIN (analyze, buffers)
SELECT SUM(amount) 
FROM transactions.transactions_large
WHERE user_id = 500000 
  AND created_at < '2026-06-01';