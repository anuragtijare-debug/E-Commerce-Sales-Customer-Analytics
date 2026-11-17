-- ============================================================
-- E-Commerce Sales & Customer Analytics
-- Analysis Queries (v2, corrected)  |  Dialect: SQLite
-- Revenue definition: orders with status IN ('Delivered','Shipped')
-- Data window: 2023-01-01 to 2025-10-28
-- Porting: strftime('%Y-%m', d) -> DATE_FORMAT(d,'%Y-%m') (MySQL) / TO_CHAR(d,'YYYY-MM') (PostgreSQL)
--          JULIANDAY(a)-JULIANDAY(b) -> DATEDIFF(a,b) (MySQL) / (a::date - b::date) (PostgreSQL)
-- ============================================================


-- ------------------------------------------------------------
-- 1. BASIC BUSINESS KPIs
-- ------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id)                                              AS total_orders,
    COUNT(DISTINCT o.customer_id)                                           AS unique_customers,
    ROUND(SUM(oi.line_total), 2)                                            AS total_revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2)               AS avg_order_value,
    SUM(oi.quantity)                                                        AS total_units_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped');


-- ------------------------------------------------------------
-- 2. MONTHLY SALES TREND
-- ------------------------------------------------------------
SELECT
    strftime('%Y-%m', o.order_date)           AS month,
    COUNT(DISTINCT o.order_id)                AS orders,
    ROUND(SUM(oi.line_total), 2)              AS revenue,
    ROUND(SUM(oi.line_total) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY strftime('%Y-%m', o.order_date)
ORDER BY month;


-- ------------------------------------------------------------
-- 3. CATEGORY PERFORMANCE (FIXED: gross profit = net revenue - cost)
-- Old version discounted the cost price as well, overstating profit.
-- ------------------------------------------------------------
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id)                                              AS orders,
    SUM(oi.quantity)                                                         AS units_sold,
    ROUND(SUM(oi.line_total), 2)                                             AS revenue,
    ROUND(SUM(oi.line_total) * 100.0 / SUM(SUM(oi.line_total)) OVER (), 2)   AS revenue_pct,
    ROUND(SUM(oi.line_total) - SUM(p.cost_price * oi.quantity), 2)           AS gross_profit,
    ROUND((SUM(oi.line_total) - SUM(p.cost_price * oi.quantity)) * 100.0
          / SUM(oi.line_total), 2)                                           AS margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY p.category
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- 4. TOP 10 PRODUCTS BY REVENUE
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                          AS units_sold,
    ROUND(SUM(oi.line_total), 2)              AS revenue,
    ROUND(AVG(oi.discount_pct) * 100, 1)      AS avg_discount_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 5. CUSTOMER SEGMENT ANALYSIS (Premium / Regular / Budget)
-- ------------------------------------------------------------
SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id)                                            AS customers,
    COUNT(DISTINCT o.order_id)                                               AS orders,
    ROUND(SUM(oi.line_total), 2)                                             AS revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT c.customer_id), 2)             AS revenue_per_customer,
    ROUND(COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT c.customer_id), 2) AS orders_per_customer
FROM customers c
LEFT JOIN orders      o  ON c.customer_id = o.customer_id AND o.status IN ('Delivered', 'Shipped')
LEFT JOIN order_items oi ON o.order_id    = oi.order_id
GROUP BY c.segment
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- 6. RFM ANALYSIS (FIXED: data-driven quintile scoring)
-- Old version used fixed thresholds that did not fit this data
-- (393 of 499 customers scored M=5) and a hard-coded reference date.
-- Now: reference date = last order date + 1 day, scores via NTILE(5).
-- 5 = best on every dimension (recent / frequent / high spend).
-- ------------------------------------------------------------
WITH ref AS (
    SELECT DATE(MAX(order_date), '+1 day') AS ref_date FROM orders
),
customer_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.segment,
        c.city,
        MAX(o.order_date)                                       AS last_order_date,
        CAST(JULIANDAY((SELECT ref_date FROM ref)) - JULIANDAY(MAX(o.order_date)) AS INTEGER) AS recency_days,
        COUNT(DISTINCT o.order_id)                              AS frequency,
        ROUND(SUM(oi.line_total), 2)                            AS monetary
    FROM customers c
    JOIN orders      o  ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY c.customer_id, c.customer_name, c.segment, c.city
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC, customer_id) AS R_score,
        NTILE(5) OVER (ORDER BY frequency ASC,     customer_id) AS F_score,
        NTILE(5) OVER (ORDER BY monetary ASC,      customer_id) AS M_score
    FROM customer_metrics
)
SELECT
    customer_id, customer_name, segment, city,
    last_order_date, recency_days, frequency, monetary,
    R_score, F_score, M_score,
    (R_score + F_score + M_score) AS RFM_total,
    CASE
        WHEN R_score >= 4 AND F_score >= 4                 THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3                 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score <= 2                 THEN 'New / Promising'
        WHEN R_score <= 2 AND F_score >= 3                 THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2                 THEN 'Hibernating'
        ELSE 'Potential Loyalists'
    END AS rfm_segment
FROM rfm_scores
ORDER BY RFM_total DESC, monetary DESC;


-- ------------------------------------------------------------
-- 7. CITY PERFORMANCE (by shipping city)
-- ------------------------------------------------------------
SELECT
    o.shipping_city                                          AS city,
    COUNT(DISTINCT o.order_id)                               AS orders,
    COUNT(DISTINCT o.customer_id)                            AS customers,
    ROUND(SUM(oi.line_total), 2)                             AS revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY o.shipping_city
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- 8. PAYMENT METHOD ANALYSIS (FIXED: counts distinct orders, not order lines)
-- ------------------------------------------------------------
SELECT
    o.payment_method,
    COUNT(DISTINCT o.order_id)                                                       AS orders,
    ROUND(COUNT(DISTINCT o.order_id) * 100.0 / SUM(COUNT(DISTINCT o.order_id)) OVER (), 2) AS order_pct,
    ROUND(SUM(oi.line_total), 2)                                                     AS revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2)                        AS aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY o.payment_method
ORDER BY orders DESC;


-- ------------------------------------------------------------
-- 9. ORDER STATUS: CANCELLATION & RETURN RATE
-- ------------------------------------------------------------
SELECT
    status,
    COUNT(*)                                                  AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)        AS percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- 10. MONTH-OVER-MONTH AND YEAR-OVER-YEAR GROWTH (FIXED: real YoY added)
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS month,
        ROUND(SUM(oi.line_total), 2)    AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    month,
    revenue,
    LAG(revenue)     OVER (ORDER BY month) AS prev_month_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
          / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2)  AS mom_growth_pct,
    LAG(revenue, 12) OVER (ORDER BY month) AS same_month_last_year,
    ROUND((revenue - LAG(revenue, 12) OVER (ORDER BY month)) * 100.0
          / NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0), 2) AS yoy_growth_pct
FROM monthly
ORDER BY month;


-- ------------------------------------------------------------
-- 11. HIGH VALUE CUSTOMERS (Top 5% by spend)
-- ------------------------------------------------------------
WITH customer_spend AS (
    SELECT
        c.customer_id, c.customer_name, c.segment,
        ROUND(SUM(oi.line_total), 2)  AS total_spend,
        COUNT(DISTINCT o.order_id)    AS orders
    FROM customers c
    JOIN orders      o  ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY c.customer_id, c.customer_name, c.segment
),
ranked AS (
    SELECT *, NTILE(20) OVER (ORDER BY total_spend DESC) AS vigintile
    FROM customer_spend
)
SELECT customer_id, customer_name, segment, total_spend, orders,
       ROUND(total_spend * 100.0 / SUM(total_spend) OVER (), 2) AS pct_of_total_revenue
FROM ranked
WHERE vigintile = 1
ORDER BY total_spend DESC;


-- ------------------------------------------------------------
-- 12. PRODUCT PROFITABILITY (Top 15 by gross profit)
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                                              AS units,
    ROUND(SUM(oi.line_total), 2)                                  AS revenue,
    ROUND(SUM(p.cost_price * oi.quantity), 2)                     AS total_cost,
    ROUND(SUM(oi.line_total) - SUM(p.cost_price * oi.quantity), 2) AS gross_profit,
    ROUND((SUM(oi.line_total) - SUM(p.cost_price * oi.quantity)) * 100.0
          / NULLIF(SUM(oi.line_total), 0), 2)                     AS margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY gross_profit DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 13. YEARLY REVENUE AND GROWTH (NEW)
-- 2025 covers Jan-Oct only, so also compare Jan-Oct of each year.
-- ------------------------------------------------------------
WITH yearly AS (
    SELECT
        strftime('%Y', o.order_date)                                              AS year,
        COUNT(DISTINCT o.order_id)                                                AS orders,
        ROUND(SUM(oi.line_total), 2)                                              AS revenue,
        ROUND(SUM(CASE WHEN CAST(strftime('%m', o.order_date) AS INTEGER) <= 10
                       THEN oi.line_total END), 2)                                AS revenue_jan_oct
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY strftime('%Y', o.order_date)
)
SELECT
    year, orders, revenue, revenue_jan_oct,
    ROUND((revenue_jan_oct - LAG(revenue_jan_oct) OVER (ORDER BY year)) * 100.0
          / LAG(revenue_jan_oct) OVER (ORDER BY year), 2) AS like_for_like_growth_pct
FROM yearly
ORDER BY year;


-- ------------------------------------------------------------
-- 14. SEASONALITY BY CALENDAR MONTH (NEW)
-- Average monthly revenue across the years that have data for that month.
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        strftime('%Y', o.order_date) AS year,
        strftime('%m', o.order_date) AS month_no,
        SUM(oi.line_total)           AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY 1, 2
)
SELECT
    month_no,
    COUNT(*)                         AS years_of_data,
    ROUND(AVG(revenue), 0)           AS avg_monthly_revenue,
    ROUND(AVG(revenue) * 100.0 / (SELECT AVG(revenue) FROM monthly), 1) AS seasonality_index
FROM monthly
GROUP BY month_no
ORDER BY month_no;


-- ------------------------------------------------------------
-- 15. REPEAT PURCHASE RATE (NEW)
-- ------------------------------------------------------------
WITH per_customer AS (
    SELECT customer_id, COUNT(*) AS orders
    FROM orders
    WHERE status IN ('Delivered', 'Shipped')
    GROUP BY customer_id
)
SELECT
    COUNT(*)                                              AS buyers,
    SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END)          AS repeat_buyers,
    ROUND(SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS repeat_rate_pct,
    ROUND(AVG(orders), 2)                                 AS avg_orders_per_buyer
FROM per_customer;


-- ------------------------------------------------------------
-- 16. DISCOUNT BAND IMPACT (NEW)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN oi.discount_pct = 0     THEN '0%'
        WHEN oi.discount_pct <= 0.10 THEN '1-10%'
        WHEN oi.discount_pct <= 0.20 THEN '11-20%'
        ELSE '21-25%'
    END                                                           AS discount_band,
    COUNT(*)                                                      AS order_lines,
    SUM(oi.quantity)                                              AS units,
    ROUND(SUM(oi.line_total), 2)                                  AS revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount_pct), 2)  AS discount_given,
    ROUND((SUM(oi.line_total) - SUM(p.cost_price * oi.quantity)) * 100.0
          / SUM(oi.line_total), 2)                                AS margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY 1
ORDER BY MIN(oi.discount_pct);
