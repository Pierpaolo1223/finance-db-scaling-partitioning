EXPLAIN (analyze, buffers)
SELECT SUM(amount), COUNT(*) 
FROM transactions.transactions_large
WHERE user_id = 500000
  AND created_at >= '2026-04-01 00:00:00' 
  AND created_at < '2026-05-01 00:00:00'; 
