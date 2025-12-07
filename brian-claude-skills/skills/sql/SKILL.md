---
name: sql
description: Use when writing, reviewing, or optimizing SQL queries. Covers PostgreSQL syntax, query patterns, schema design, indexing, and performance tuning. Triggers on SQL file creation, query optimization, schema migrations, or database design. For Python ORM usage, see python-backend skill.
---

# SQL Development

Use PostgreSQL as the default database. Write clear, performant SQL.

## Principles

**Query Design**
- **Explicit columns** - Never use `SELECT *` in production code; list columns explicitly
- **Qualify column names** - Use table aliases and qualify ambiguous columns in joins
- **CTEs for readability** - Use Common Table Expressions to break complex queries into logical steps
- **Avoid subqueries in SELECT** - Move correlated subqueries to JOINs or CTEs
- **NULL-aware comparisons** - Use `IS NULL` / `IS NOT NULL`; remember `NULL != NULL`

**Schema Design**
- **Normalize first** - Start normalized; denormalize only with measured performance need
- **Consistent naming** - Use snake_case; plural table names (`users`), singular columns (`user_id`)
- **Always have a primary key** - Prefer `BIGINT GENERATED ALWAYS AS IDENTITY`
- **Foreign key constraints** - Enforce referential integrity at the database level
- **Timestamps on all tables** - Include `created_at` and `updated_at` columns

**Performance**
- **EXPLAIN ANALYZE first** - Profile before optimizing; don't guess at bottlenecks
- **Index for access patterns** - Create indexes based on WHERE, JOIN, and ORDER BY usage
- **Composite index order matters** - Place high-cardinality and equality columns first
- **Avoid functions on indexed columns** - `WHERE created_at::date = '2024-01-01'` can't use index
- **LIMIT early** - Apply limits in subqueries/CTEs when possible, not just at the end

**Security**
- **Parameterized queries only** - Never interpolate user input into SQL strings
- **Principle of least privilege** - Grant minimum required permissions to application users
- **Row-level security** - Use RLS policies for multi-tenant data isolation

## Running SQL

```bash
# Connect to PostgreSQL
psql -h localhost -U username -d database_name

# Run SQL file
psql -h localhost -U username -d database_name -f script.sql

# Run single query
psql -h localhost -U username -d database_name -c "SELECT version();"
```

## Query Patterns

### Basic CRUD

```sql
-- Insert with returning
INSERT INTO users (email, name)
VALUES ('user@example.com', 'Test User')
RETURNING id, created_at;

-- Update with conditions
UPDATE users
SET name = 'New Name', updated_at = NOW()
WHERE id = 123
RETURNING *;

-- Upsert (insert or update)
INSERT INTO users (email, name)
VALUES ('user@example.com', 'Test User')
ON CONFLICT (email) DO UPDATE
SET name = EXCLUDED.name, updated_at = NOW();

-- Soft delete pattern
UPDATE users
SET deleted_at = NOW()
WHERE id = 123;
```

### Joins

```sql
-- Explicit JOIN syntax (never implicit)
SELECT u.id, u.name, COUNT(p.id) AS post_count
FROM users u
LEFT JOIN posts p ON p.author_id = u.id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.name;

-- Multiple joins
SELECT o.id, u.name, p.title
FROM orders o
INNER JOIN users u ON u.id = o.user_id
INNER JOIN products p ON p.id = o.product_id
WHERE o.status = 'completed';
```

### Common Table Expressions (CTEs)

```sql
-- Break complex queries into steps
WITH active_users AS (
    SELECT id, name, email
    FROM users
    WHERE last_login_at > NOW() - INTERVAL '30 days'
),
user_orders AS (
    SELECT user_id, COUNT(*) AS order_count, SUM(total) AS total_spent
    FROM orders
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT 
    au.name,
    au.email,
    COALESCE(uo.order_count, 0) AS order_count,
    COALESCE(uo.total_spent, 0) AS total_spent
FROM active_users au
LEFT JOIN user_orders uo ON uo.user_id = au.id
ORDER BY uo.total_spent DESC NULLS LAST;
```

### Window Functions

```sql
-- Row number for pagination/ranking
SELECT 
    id,
    name,
    score,
    ROW_NUMBER() OVER (ORDER BY score DESC) AS rank
FROM players;

-- Running totals
SELECT 
    date,
    amount,
    SUM(amount) OVER (ORDER BY date) AS running_total
FROM transactions;

-- Partition by group
SELECT 
    department,
    name,
    salary,
    AVG(salary) OVER (PARTITION BY department) AS dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department) AS diff_from_avg
FROM employees;

-- LAG/LEAD for comparing rows
SELECT 
    date,
    revenue,
    LAG(revenue) OVER (ORDER BY date) AS prev_revenue,
    revenue - LAG(revenue) OVER (ORDER BY date) AS change
FROM daily_sales;
```

### Aggregations

```sql
-- Conditional aggregation
SELECT 
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed,
    COUNT(*) FILTER (WHERE status = 'pending') AS pending,
    SUM(total) FILTER (WHERE status = 'completed') AS completed_revenue
FROM orders;

-- Group by with rollup
SELECT 
    COALESCE(region, 'TOTAL') AS region,
    COALESCE(category, 'ALL') AS category,
    SUM(sales) AS total_sales
FROM sales
GROUP BY ROLLUP (region, category);
```

## Schema Patterns

### Table Creation

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index for common queries
CREATE INDEX ix_users_created_at ON users (created_at DESC);
CREATE INDEX ix_users_metadata ON users USING GIN (metadata);
```

### Foreign Keys

```sql
CREATE TABLE posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Composite index for author queries
CREATE INDEX ix_posts_author_published ON posts (author_id, published_at DESC);
```

### Enums

```sql
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'completed', 'cancelled');

CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status order_status DEFAULT 'pending' NOT NULL,
    -- ...
);
```

## PostgreSQL Features

### JSONB

```sql
-- Query JSONB fields
SELECT * FROM users WHERE metadata->>'role' = 'admin';
SELECT * FROM users WHERE metadata @> '{"verified": true}';

-- Update JSONB
UPDATE users
SET metadata = metadata || '{"onboarded": true}'
WHERE id = 123;

-- Remove JSONB key
UPDATE users
SET metadata = metadata - 'temporary_field'
WHERE id = 123;
```

### Arrays

```sql
-- Array column
ALTER TABLE posts ADD COLUMN tags TEXT[] DEFAULT '{}';

-- Query arrays
SELECT * FROM posts WHERE 'sql' = ANY(tags);
SELECT * FROM posts WHERE tags @> ARRAY['sql', 'postgresql'];

-- Unnest for joining
SELECT p.id, tag
FROM posts p, UNNEST(p.tags) AS tag
WHERE tag LIKE 'postgres%';
```

### Full-Text Search

```sql
-- Add search vector column
ALTER TABLE posts ADD COLUMN search_vector TSVECTOR;

-- Populate and index
UPDATE posts SET search_vector = to_tsvector('english', title || ' ' || content);
CREATE INDEX ix_posts_search ON posts USING GIN (search_vector);

-- Query
SELECT id, title
FROM posts
WHERE search_vector @@ to_tsquery('english', 'postgresql & performance')
ORDER BY ts_rank(search_vector, to_tsquery('english', 'postgresql & performance')) DESC;
```

## Performance Analysis

```sql
-- Analyze query execution
EXPLAIN ANALYZE
SELECT u.name, COUNT(p.id)
FROM users u
LEFT JOIN posts p ON p.author_id = u.id
GROUP BY u.id;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Find missing indexes (sequential scans on large tables)
SELECT 
    schemaname,
    relname,
    seq_scan,
    seq_tup_read,
    idx_scan
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC;
```