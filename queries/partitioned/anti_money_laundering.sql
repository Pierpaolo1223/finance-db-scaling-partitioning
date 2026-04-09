EXPLAIN (analyze, buffers) 
SELECT * FROM transactions.transactions_partitioned 
WHERE created_at BETWEEN '2026-05-15 14:00:00' AND '2026-05-15 15:00:00' AND amount > 9000;