EXPLAIN (analyze, buffers)
SELECT user_id, SUM(amount) FROM transactions.transactions_large
WHERE created_at BETWEEN '2026-01-01' AND '2026-03-31' AND user_id BETWEEN 100 AND 200 GROUP BY user_id;