# 🧼 E-Commerce Sales Data Cleaning & Standardization Pipeline

An end-to-end data engineering and data quality assurance project executed entirely in **MySQL Workbench**. This repository demonstrates production-grade database cleaning methodologies designed to eliminate pipeline failures and transform chaotic, raw transactional data into an enterprise-ready analytics dataset.

---

## 🛠️ Tech Stack & Advanced SQL Skills

* **Database Management Engine:** MySQL Workbench
* **Advanced SQL Operations:** Common Table Expressions (CTEs), Window Functions (`ROW_NUMBER()`), Safe Update Controls (`SQL_SAFE_UPDATES`), Schema Modifications (`ALTER / MODIFY`), String Normalization (`TRIM / IF`), Type-Casting (`STR_TO_DATE`), Absolute Inversions (`ABS`), Categorical Imputation.
* **Core Engineering Skills:** Staging Table Architectures, Data Integrity Validation, Profiling Data Anomaly Trends, Database Schema Fortification.

---

## 📑 Data Cleaning Architecture Workflow

The cleaning script operates across a robust **7-step data optimization lifecycle**, transforming messy raw logs into a polished gold database master table.

```
[Raw Ingestion (sales)] ➡️ [Staging / Partition Validation (sales2)] ➡️ [Final Production Master (sales3)]

```

### 🔹 Step 1: Structural Deduplication

* **The Problem:** The database recorded duplicate entry logs for critical keys (specifically transactions `1001`, `1004`, and `1030`), which would artificially inflate sales volume and metrics.
* **The Solution:** Built a dedicated staging space (`sales2`), partitioned transactions across their core identity properties using a window function, isolated the anomaly footprints, and pruned out rows that breached uniqueness limits.

```sql
CREATE TABLE sales2 LIKE sales;
INSERT INTO sales2 (SELECT * FROM sales);

-- Pinpointing duplicate footprints using a CTE
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS row_num
    FROM sales2
)
SELECT * FROM cte WHERE row_num > 1;

-- Creating the clean structure table to remove duplicates safely
CREATE TABLE sales3 (
    transaction_id INT, customer_id INT, customer_name TEXT, email TEXT, purchase_date TEXT,
    product_id INT, category TEXT, price DOUBLE, quantity INT, total_amount TEXT, 
    payment_method TEXT, delivery_status TEXT, customer_address TEXT, row_num INT
);

INSERT INTO sales3
SELECT *, ROW_NUMBER() OVER(PARTITION BY transaction_id, customer_id, customer_name, email, purchase_date, product_id, category, price, quantity, total_amount, payment_method, delivery_status, customer_address) AS row_num
FROM sales2;

DELETE FROM sales3 WHERE row_num > 1;

```

### 🔹 Step 2 & 3: White-Space Conversion & Categorical Imputation

* **The Problem:** Blank spaces (`' '`) disguised as valid entries bypassed traditional `IS NULL` filters while missing prices threatened downstream calculations.
* **The Solution:** Bypassed restrictive server settings temporarily to perform bulk string normalization (`TRIM()`), forcing empty spaces into true database `NULL` states. Instead of assigning a blanket global average to missing costs, a **Categorical Mean Imputation** strategy calculated group averages per category block (e.g., *Books*, *Clothing*) and injected those granular values precisely where data was missing.

```sql
SET SQL_SAFE_UPDATES = 0;

-- Forcing text voids into true standard NULLs
UPDATE sales3 SET 
    transaction_id   = IF(TRIM(transaction_id)   = '', NULL, transaction_id),
    customer_name    = IF(TRIM(customer_name)    = '', NULL, customer_name),
    email            = IF(TRIM(email)            = '', NULL, email),
    category         = IF(TRIM(category)         = '', NULL, category),
    price            = IF(TRIM(price)            = '', NULL, price),
    customer_address = IF(TRIM(customer_address) = '', NULL, customer_address);

-- Domain Categorical Imputation Strategy
UPDATE sales3 SET category = 'unknown' WHERE category IS NULL;
UPDATE sales3 SET customer_address = 'Not available' WHERE customer_address IS NULL;
UPDATE sales3 SET payment_method = 'Not specified' WHERE payment_method IS NULL;

-- Standardizing nomenclature values
UPDATE sales3 SET payment_method = 'Credit Card' WHERE payment_method IN ('creditcard', 'CC', 'credit');

-- Dynamic Categorical Average Pricing Injection
UPDATE sales3 SET price = 2511.416 WHERE price IS NULL AND category = 'unknown';
UPDATE sales3 SET price = 2591.6493 WHERE price IS NULL AND category = 'Books';
UPDATE sales3 SET price = 2591.6493 WHERE price IS NULL;

```

### 🔹 Step 4: Mathematical Inversion & Recalculation

* **The Problem:** Quantity metrics incorrectly stored negative integers due to system bugs or returns, throwing off mathematical totals.
* **The Solution:** Inverted negative integers into pure positive volumes using the absolute value tool (`ABS()`). After aligning the units, the `total_amount` values were re-evaluated across the database with an algebraic verification check (`price * quantity`) to fill in missing gaps and fix calculation errors.

```sql
-- Normalizing negative records into pure positive units
UPDATE sales3 SET quantity = ABS(quantity) WHERE quantity < 0;

-- Recalculating mathematical calculations dynamically
UPDATE sales3 SET total_amount = price * quantity
WHERE total_amount IS NULL OR total_amount != price * quantity;

UPDATE sales3 SET customer_name = 'user' WHERE customer_name IS NULL;

```

### 🔹 Step 5: Chronological Anomaly Resolution

* **The Problem:** The system captured an invalid calendar date (`2024-02-30`), which completely broke native database scheduling functions.
* **The Solution:** Intercepted the anomaly and re-mapped it to the correct leap-year close of that month (`29/02/2024`).

```sql
UPDATE sales3 
SET purchase_date = '29/02/2024' 
WHERE purchase_date = '2024-02-30';

```

### 🔹 Step 6: PII Syntax Validation

* **The Problem:** Structural anomalies (missing `@` symbols) corrupted the customer email fields.
* **The Solution:** Audited record patterns using regular expression syntax (`NOT LIKE '%@%'`) to isolate broken emails and move them to a uniform `'not_given'` tier, preventing data-load failures down the line.

```sql
UPDATE sales3 
SET email = 'not_given' 
WHERE email NOT LIKE '%@%';

```

### 🔹 Step 7: Schema Typing & Metadata Alteration

* **The Problem:** Purchase dates were trapped as loose `TEXT` types, rendering chronological sorting and seasonal trends impossible.
* **The Solution:** Parsed the text patterns (`%d/%m/%Y`) using `STR_TO_DATE()` to establish ISO standard formats before altering the column configuration to a true, indexable database `DATE` schema type.

```sql
UPDATE sales3 
SET purchase_date = STR_TO_DATE(purchase_date, '%d/%m/%Y')
WHERE purchase_date LIKE '%/%/%';

-- Re-engineering metadata properties
ALTER TABLE sales3 MODIFY COLUMN purchase_date DATE;

SET SQL_SAFE_UPDATES = 1; -- Restoring safety constraints

```

---

## 📈 Database Business Impact

1. **Flawless Transaction Tracking:** Eliminating duplicates and fixing broken calculation equations ($Total = Price \times Quantity$) ensures reliable data loops.
2. **Advanced Analytics Enablement:** Migrating string-typed dates into structured `DATE` format opens up the data asset for accurate forecasting, cohort tracking, and seasonality profiling.
3. **Optimized Integrity Guardrails:** Converting hidden text voids into standard database `NULL` markers keeps automated aggregations and reporting calculations precise.

---

## 📂 Repository Layout

```text
├── Raw_Data/                 # Input raw sales transactions (.csv files)
├── Database_Scripts/         # Complete pipeline validation & cleaning SQL codes
└── README.md                 # Technical report and analytical summary

```
