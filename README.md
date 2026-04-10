# Finance DB Scaling & Partitioning: A Strategic Approach

This project explores PostgreSQL performance and architectural scalability for financial datasets. It compares a standard "flat" monolithic table against a **hybrid partitioning** strategy, simulating the infrastructure of a company designed to scale to **Unicorn levels within 5 years**.

## The "Strategic vs Technical" Vision

While a 20M record dataset (approx. 1.5GB) currently fits into modern RAM, this project adopts partitioning as a **preventive architectural choice**. 

In an enterprise hyper-growth phase, transaction tables must compete for RAM with users, notifications, and other critical services. Designing for partitioning "Day 1" is a strategic investment: it avoids catastrophic technical debt and high-risk, multi-terabyte migrations when the dataset inevitably hits the "RAM Wall" (moving from 20M to 2B+ records).

### The T2D3 Growth Projection
This architecture is built following the **T2D3 model** (Triple, Triple, Double, Double, Double) — the gold standard for SaaS hyper-growth. Starting with 20M annual records, a successful company can expect to manage over **1.4 Billion records within 5 years** (a ~72x increase). Implementing partitioning at the 20M stage is a proactive move to ensure the database layer never becomes the bottleneck during this exponential expansion.

## Architecture: Hybrid Partitioning

To optimize both time-based reporting and user-specific lookups, we implemented a two-level hierarchy:

- **Level 1 (Range)**: Monthly partitions based on `created_at`.
- **Level 2 (Hash)**: Each monthly partition is further sub-partitioned into **4 Hash buckets** based on `user_id` to balance I/O.

**Note on Indexing**: To isolate the structural benefits of **Partition Pruning**, this experiment deliberately uses **only Primary Keys**. This ensures the measured performance gap is due to architectural efficiency and I/O reduction, rather than specific query tuning.

## Synergizing Indexing and Partitioning

It is important to note that in production environments, **indexing and partitioning are complementary**, not mutually exclusive:

- **Indexing (Pure Speed)**: Provides the microscopic efficiency needed to find specific rows within a dataset.
- **Partitioning (Systemic Efficiency)**: Provides the macroscopic structure needed to keep indexes manageable, ensure cache density, and enable administrative agility.

**Operational Best Practice**: Typically, in high-volume scenarios, the architecture is **partitioned first, then indexed**. This ensures that indexes remain local to each shard, reducing maintenance overhead and improving bulk ingestion speed.

## Why Partitioning Over Simple Indexing?

Beyond raw query speed, partitioning provides critical **Operational Scalability**:

- **Cache Protection & Thrashing Prevention**: By leveraging **Partition Pruning**, the engine avoids loading irrelevant data into the `shared_buffers`. This prevents "Cache Pollution," ensuring that heavy analytical queries don't evict critical application data from memory.
- **Efficient Data Lifecycle (DROP vs DELETE)**: Managing 10 years of data requires surgical precision. Removing old months via `DROP TABLE` is instantaneous and generates **zero bloat**, whereas a massive `DELETE` on a monolith would choke the Autovacuum for hours.
- **Maintenance Predictability & Lock Mitigation**: Maintenance tasks like `REINDEX` or `VACUUM` are performed on smaller, manageable shards. This provides **operational isolation**: a lock on a specific shard doesn't affect the availability of the rest of the dataset.

## Automation & Production Readiness

In a real-world production environment, partition management should not be manual. 

- **pg_partman**: For a truly scalable architecture, tools like **`pg_partman`** should be used to automate shard creation and data retention. 
- **Infrastructure as Code**: This setup is designed to be integrated into CI/CD pipelines, ensuring the schema evolves seamlessly with company growth.

## Benchmarks & Environment Setup

To simulate high-pressure environments where data exceeds available memory, we restricted the PostgreSQL Buffer Pool to force **physical I/O**.

### 1. Hardware & Software
- **Database**: PostgreSQL 14.22
- **Processor**: Intel Core i7-6700HQ (4 Cores, 8 Threads @ 2.60GHz)
- **System Memory**: 16GB DDR4
- **OS**: Linux

### 2. Limit the Buffer Pool
```sql
ALTER SYSTEM SET shared_buffers = '64MB'; -- Restart PostgreSQL service after this
```

### 3. Memory Residency & OS Page Cache Interference
PostgreSQL relies heavily on the **OS Page Cache**. In a monolithic setup, a large sequential scan "pollutes" the cache with cold data, evicting critical hot pages (like those from the `users` or `sessions` tables). 

Partitioning solves this via **Working Set Isolation**: 
- Only the active partition's pages are pulled into memory.
- It reduces **CPU Context Switching** by minimizing the number of system calls required to swap pages in/out of the `shared_buffers`.
- It ensures a higher **Cache Hit Ratio** for the rest of the application ecosystem.

**The "It Depends" Principle (Architecture over Dogma)**: 
- **Low-Churn/Static Datasets**: Standard indexing remains the gold standard for simplicity and low overhead.
- **High-Churn/Hyper-growth Datasets**: Partitioning is an operational survival requirement to prevent **Index Bloat** and IOPS starvation.

## Script Execution Order

1. **`scripts/setup_infrastructure.sql`**: Infrastructure setup. Identifiers are handled via **`%I`** (PostgreSQL format) to ensure metadata integrity and SQL safety.
2. **`scripts/data_ingestion.sql`**: Populates ~20M records for both partitioned and large table.
3. **`scripts/check_distribution.sql`**: Verifies the hybrid strategy.
