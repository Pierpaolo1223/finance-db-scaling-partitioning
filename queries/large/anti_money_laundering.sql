EXPLAIN (analyze, buffers) 
SELECT user_id, amount, created_at
FROM transactions.transactions_large
WHERE user_id = 500000 and created_at BETWEEN '2026-05-15 14:00:00' AND '2026-05-15 15:00:00'
  AND amount > 10000;
