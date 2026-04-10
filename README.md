# Finance DB Scaling & Partitioning: A Strategic Approach

This project explores PostgreSQL performance and architectural scalability for financial datasets. It compares a standard "flat" monolithic table against a **hybrid partitioning** strategy, simulating the infrastructure of a company designed to scale to **Unicorn levels within 5 years**.

## Installation and Monitoring

Follow these steps to initialize the experiment and test the architecture under load:

### 1. Copy the example file:

   ```bash
   cp .env.example .env
   # Open your .env file and set your DB_PASSWORD
   ```

### 2. Infrastructure Startup
Use Docker to spin up the PostgreSQL instance with the 64MB memory restriction configured for this test:
```bash
docker compose up -d
```

### 3. Database Access
Access the container to interact directly with the transactions dataset:
```bash
docker exec -it finance_scaling_experiment psql -U postgres -d transactions
```

### 4. Query Monitoring
To monitor active queries, their duration, and resource status in real-time during load tests, run the following SQL command:

```sql
SELECT 
    pid, 
    now() - query_start AS duration, 
    query, 
    state
FROM pg_stat_activity
WHERE state != 'idle' 
  AND query NOT LIKE '%pg_stat_activity%';
```
Tip: Use this command to verify if the data ingestion process has been completed before starting your benchmarks.

### 5. Running Benchmarks
Execute the various comparison queries provided in the **queries** table. This allows you to directly measure the performance gap between the monolithic and partitioned tables on your own hardware, observing how **Partition Pruning** effectively minimizes physical I/O.

---
<br>

## Architecture & Strategy

### The "Strategic vs Technical" Vision (T2D3 Model)
While a 20M record dataset (~1.5GB) fits in RAM today, this project adopts partitioning as a **preventive architectural choice**. 

Following the **T2D3 model** (Triple, Triple, Double, Double, Double), a successful SaaS can grow from 20M to **1.4 Billion records within 5 years**. Designing for partitioning "Day 1" avoids catastrophic technical debt and high-risk, multi-terabyte migrations when the dataset inevitably hits the "RAM Wall."

### Hybrid Partitioning Structure
To optimize both time-based reporting and user-specific lookups, we implemented a two-level hierarchy:
- **Level 1 (Range)**: Monthly partitions based on `created_at`.
- **Level 2 (Hash)**: Each monthly partition is further sub-partitioned into **4 Hash buckets** based on `user_id` to balance I/O.

*Note: To isolate the benefits of Partition Pruning, this experiment uses **only Primary Keys**. This ensures performance gains are due to architectural efficiency, not specific query tuning.*

### Why Partitioning Over Simple Indexing?
*   **Cache Protection**: Prevents "Cache Pollution" by loading only relevant partitions into `shared_buffers`, avoiding thrashing.
*   **Efficient Data Lifecycle**: Removing old data via `DROP TABLE` is instantaneous and generates **zero bloat**, unlike massive `DELETE` operations.
*   **Maintenance Predictability**: Tasks like `REINDEX` or `VACUUM` are performed on smaller shards, providing operational isolation and preventing global table locks.
*   **Automation**: In production, tools like `pg_partman` should be used to automate shard creation and retention.

### Memory Residency & OS Page Cache Interference
PostgreSQL relies heavily on the **OS Page Cache**. In a monolithic setup, a large sequential scan "pollutes" the cache with cold data, evicting critical hot pages (like those from the `users` or `sessions` tables). 

Partitioning solves this via **Working Set Isolation**: 
- Only the active partition's pages are pulled into memory.
- It reduces **CPU Context Switching** by minimizing the number of system calls required to swap pages in/out of the `shared_buffers`.
- It ensures a higher **Cache Hit Ratio** for the rest of the application ecosystem.

---
<br>

**The "It Depends" Principle (Architecture over Dogma)**: 
- **Low-Churn/Static Datasets**: Standard indexing remains the gold standard for simplicity and low overhead.
- **High-Churn/Hyper-growth Datasets**: Partitioning is an operational survival requirement to prevent **Index Bloat** and IOPS starvation.

---
<br>

## Key Takeaways & Conclusions

> - **Architecture beats Hardware**: Even with restricted memory (64MB), a well-partitioned system usually outperformed the monolith by minimizing I/O overhead.
> - **Operational Resilience**: Partitioning is not just about query speed; it’s about making maintenance (backups, reindexing, purging) predictable and safe without global table locks.
> - **Future-Proofing**: Implementing this strategy during early growth (20M-40M records) prevents massive technical debt when reaching the **T2D3 Unicorn scale** (billions of rows).
> - **System Hygiene**: Sharding enables instant data lifecycle management via `DROP/DETACH`, preventing **Autovacuum saturation** and permanent index bloat.