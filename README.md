# E-Commerce Sales & Customer Analytics

![SQL](https://img.shields.io/badge/SQL-SQLite-blue) ![Excel](https://img.shields.io/badge/Excel-Dashboard-green) ![Python](https://img.shields.io/badge/Python-Loader-yellow) ![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

A SQL and Excel portfolio project analyzing e-commerce sales performance, category and product contribution, customer value (RFM), discount effectiveness, regional distribution and seasonality.

The project combines customer, product, order and order-item data to generate business-focused insights from 2,500 orders covering January 2023 to October 2025.

**Live web dashboard:** `<paste your shared dashboard link here>`

## 📑 Table of Contents

- [About This Project](#about-this-project)
- [Problem Statement](#problem-statement)
- [Business Questions](#business-questions)
- [Dataset Overview](#dataset-overview)
- [Project Structure](#project-structure)
- [Methodology](#methodology)
  - [1. SQL Data Preparation](#1-sql-data-preparation)
  - [2. SQL Business Analysis](#2-sql-business-analysis)
  - [3. KPI Calculation](#3-kpi-calculation)
  - [4. Dashboards](#4-dashboards)
- [Key Findings](#key-findings)
- [Business Recommendations](#business-recommendations)
- [Technical Specifications](#technical-specifications)
- [How to Review the Project](#how-to-review-the-project)
- [Limitations](#limitations)
- [Author](#author)

## About This Project

This project analyzes online retail activity using SQL for data preparation and business analysis, and Excel plus a web page for visualization.

The analysis focuses on revenue and margin trends, the contribution of categories, products, cities and payment methods, customer segmentation with RFM, and the effect of discounts.

The project demonstrates:

- **SQL data preparation:** Loading four related tables, enforcing keys and validating the data.
- **Business-oriented SQL analysis:** Answering six defined business questions through 16 analytical queries.
- **Advanced SQL techniques:** CTEs, window functions (`SUM() OVER`, `LAG`, `NTILE`), conditional aggregation and `CASE` segmentation.
- **KPI calculation:** Revenue, orders, average order value, gross profit, margin and repeat rate.
- **Dashboard reporting:** An Excel dashboard with eight charts and live formulas, and a responsive web dashboard.
- **Business interpretation:** Turning patterns into practical recommendations while acknowledging data limitations.

## Problem Statement

E-commerce performance varies across time, categories, customers, cities and discount levels. Looking at one number, such as total revenue, can hide a declining trend, a weak season or a margin problem.

This project uses order-level data to find where revenue comes from, where it is leaking, and which customers matter most.

## Business Questions

1. **Overall Performance:** What are the revenue, order volume, average order value, margin and repeat rate?
2. **Trends and Seasonality:** How does revenue change over time, and which months are strongest and weakest?
3. **Category and Product Performance:** Which categories and products contribute most to revenue and gross profit?
4. **Customer Value:** Which customers drive revenue, and which are at risk of leaving?
5. **Discount Effectiveness:** Do deeper discounts increase volume, and what do they cost in margin?
6. **Geography and Payments:** Which cities and payment methods account for the largest share of orders?

## Dataset Overview

The project uses four source CSV files.

| Dataset | Description |
|---|---|
| `customers.csv` | Customer details: city, state, segment (Premium / Regular / Budget), join date |
| `products.csv` | Product details: category, sub-category, unit price, cost price |
| `orders.csv` | Order headers: date, status, payment method, shipping city |
| `order_items.csv` | Order lines (fact table): quantity, unit price, discount, line total |

### Dataset Summary

| Attribute | Details |
|---|---|
| Analysis period | January 2023 – October 2025 (data ends 28 Oct 2025) |
| Orders | 2,500 (2,195 Delivered or Shipped) |
| Order lines | 6,320 |
| Customers | 500 |
| Products | 75 in 5 categories |
| Source format | CSV |

Revenue is calculated from orders with status `Delivered` or `Shipped`. Cancelled and Returned orders are excluded.

## Project Structure

```
E-Commerce-Sales-Customer-Analytics/
│
├── Dataset/
│   ├── customers.csv
│   ├── products.csv
│   ├── orders.csv
│   └── order_items.csv
│
├── SQL/
│   ├── 01_Schema.sql
│   ├── 02_Analysis_Queries.sql
│   └── 03_Load_Data.py
│
├── SQL Output/
│   ├── Q01_KPI_Summary.csv
│   ├── Q02_Monthly_Sales_Trend.csv
│   ├── ...
│   └── Q16_Discount_Bands.csv
│
├── Excel Dashboard/
│   └── Ecommerce_Sales_Analytics_Dashboard.xlsx
│
├── Web Dashboard/
│   └── Ecommerce_Dashboard.html
│
├── Screenshots/
│   ├── Excel_Dashboard.png
│   ├── Web_Page_1_Overview_and_Findings.png
│   ├── Web_Page_2_Revenue_Products_Cities.png
│   └── Web_Page_3_Customers_RFM_Discounts.png
│
├── Documentation/
│   └── Ecommerce_Sales_Analytics_Report.pdf
│
└── README.md
```

## Methodology

### 1. SQL Data Preparation

`SQL/01_Schema.sql` creates four tables with primary keys, foreign keys and four indexes on the join and filter columns. `SQL/03_Load_Data.py` loads the CSV files into a SQLite database and checks foreign keys.

Validation performed on the data:

- No foreign key violations.
- `line_total` equals `quantity × unit_price × (1 − discount)` on all 6,320 rows.
- Item prices match the product table.
- Known quirks, left unchanged: 2,161 orders ship to a city other than the customer's home city, and 439 orders are dated before the customer's `join_date`.

### 2. SQL Business Analysis

`SQL/02_Analysis_Queries.sql` contains 16 queries. Each result is saved in `SQL Output/`.

| Query | Purpose | Technique |
|---|---|---|
| Q01 | Revenue, orders, buyers, AOV | `COUNT(DISTINCT)` |
| Q02 | Monthly sales trend | `GROUP BY strftime` |
| Q03 | Category revenue share and gross profit | `SUM(SUM()) OVER ()` |
| Q04 | Top 10 products | `ORDER BY ... LIMIT` |
| Q05 | Premium / Regular / Budget segments | `LEFT JOIN` |
| Q06 | RFM customer segmentation | CTEs, `NTILE(5)`, `CASE` |
| Q07 | City performance | `GROUP BY` |
| Q08 | Payment methods | `COUNT(DISTINCT)` in a window |
| Q09 | Cancellation and return rate | window percentage |
| Q10 | Month-over-month and year-over-year growth | `LAG(x)`, `LAG(x, 12)` |
| Q11 | Top 5% customers | `NTILE(20)` |
| Q12 | Product profitability | revenue minus cost |
| Q13 | Like-for-like yearly growth | conditional `SUM` |
| Q14 | Seasonality index | monthly averages |
| Q15 | Repeat purchase rate | conditional aggregation |
| Q16 | Discount band impact | `CASE` bands |

### 3. KPI Calculation

| KPI | Definition |
|---|---|
| Revenue | `SUM(line_total)` for Delivered and Shipped orders |
| Orders | `COUNT(DISTINCT order_id)` |
| Average Order Value | Revenue ÷ orders |
| Gross Profit | `SUM(line_total) − SUM(cost_price × quantity)` |
| Gross Margin | Gross profit ÷ revenue |
| Repeat Rate | Buyers with 2+ orders ÷ all buyers |

**RFM scoring:** recency, frequency and monetary value are each scored 1–5 with `NTILE(5)` (5 = best). Recency is measured from the day after the last order in the data. Segments: Champions, Loyal Customers, New / Promising, At Risk, Hibernating and Potential Loyalists.

**Important:** Gross profit uses product cost only. Shipping, returns handling and marketing costs are not in the dataset.

### 4. Dashboards

**Excel dashboard** (`Excel Dashboard/`): KPI tiles, six key findings with actions, and eight charts. Each chart reads from its own data tab, which names the query it came from. Shares, growth rates and totals are live formulas.

**Web dashboard** (`Web Dashboard/`): the same findings with hover tooltips, light and dark themes, and a layout that works on phones. Open the HTML file in any browser.

### Dashboard Screenshots

#### Excel Dashboard
![Excel Dashboard](Screenshots/Excel_Dashboard.png)

#### Web Dashboard
![Overview and Findings](Screenshots/Web_Page_1_Overview_and_Findings.png)
![Revenue, Products and Cities](Screenshots/Web_Page_2_Revenue_Products_Cities.png)
![Customers, RFM and Discounts](Screenshots/Web_Page_3_Customers_RFM_Discounts.png)

## Key Findings

### 1. Revenue Trend
- Revenue fell from ₹2.84 Cr (2023) to ₹2.49 Cr (2024), a drop of 12%.
- Comparing January–October of each year, 2025 is down a further 2.3% on 2024.
- Orders fell from 823 to 710 to 662 while average order value stayed near ₹34,000.
- **Interpretation:** The decline comes from fewer orders, not smaller baskets.

### 2. Seasonality
- October to December are the weakest months in every year: the seasonality index is 55 for October, 50 for November and 38 for December (100 = average month).
- May (146), July (137) and January (128) are the strongest.
- **Interpretation:** The data shows no festive-season lift. November and December have only two years of data.

### 3. Discounts
- Gross margin is 38.0% on undiscounted lines and 19.6% at 21–25% off.
- Average units per order line stay near 2.0 in every discount band. Total discounts given were ₹62 L.
- **Interpretation:** Deeper discounts reduced margin without lifting units per order. This is a correlation, not a controlled test.

### 4. Categories and Products
- Electronics is 71.8% of revenue (₹5.44 Cr); category margins all sit between 32.7% and 33.2%.
- Smartwatch 2 is the top product at ₹94.0 L (12.4% of revenue).
- **Interpretation:** Revenue is highly concentrated in one category with no margin advantage over the others.

### 5. Customers
- Champions and Loyal customers (220 customers, 44%) bring ₹4.6 Cr, about 61% of revenue.
- 79 At Risk customers (₹1.3 Cr, 17.5% of revenue) have been inactive for about 13 months on average.
- The top 5% of customers account for 15.4% of revenue.
- **Interpretation:** A minority of customers carries most of the revenue, and a sizeable group has gone quiet.

### 6. Cities and Payments
- Bangalore (₹107.8 L), Pune (₹105.8 L) and Ahmedabad (₹104.4 L) lead; Mumbai is last at ₹75.6 L.
- UPI carries 44.7% of orders, and order value is similar across payment methods.
- Premium, Regular and Budget customers each spend about ₹1.5 L, so the segment label does not predict spend.

### Overall KPI Summary

| Metric | Result |
|---|---|
| Revenue | ₹7.58 Cr |
| Valid Orders | 2,195 |
| Buyers | 499 |
| Average Order Value | ₹34,552 |
| Gross Profit | ₹2.50 Cr (32.9% margin) |
| Repeat Rate | 94.6% |
| Cancelled + Returned | 12.2% of orders |
| Analysis Period | January 2023 – October 2025 |

## Business Recommendations

1. **Win back At Risk customers first:** Send a targeted offer to the 79 customers silent for about 13 months, and limit Hibernating customers to low-cost reactivation.
2. **Plan for October–December:** Test a campaign for the weakest quarter and stock up ahead of the May and July peaks.
3. **Cap discounts:** Limit discounts near 10% and A/B test the cap, since deeper discounts reduced margin without raising units per order.
4. **Reduce Electronics concentration:** Grow Home and Sports, the next two categories by revenue, while protecting Electronics stock.
5. **Investigate Mumbai:** Review fulfilment and marketing in the lowest-revenue city.
6. **Target by RFM:** Use RFM segments, not the Premium / Regular / Budget label, for campaigns.

These recommendations reflect patterns in the available dataset and are not a substitute for profitability or operational analysis.

## Technical Specifications

| Component | Technology / Approach |
|---|---|
| Data input | CSV files |
| Database | SQLite |
| Data preparation | SQL schema, keys and indexes; Python loader |
| Business analysis | SQL joins, CTEs, window functions, conditional aggregation |
| Dashboards | Excel (native charts, live formulas) and HTML / JavaScript |
| Output formats | CSV, XLSX, HTML, PNG, PDF, Markdown |
| Analysis type | Descriptive and exploratory business analysis |

## How to Review the Project

### 1. Review the Source Data
Open the files in `Dataset/`.

### 2. Run the SQL

```bash
python SQL/03_Load_Data.py                        # creates ecommerce.db and checks foreign keys
sqlite3 ecommerce.db < SQL/02_Analysis_Queries.sql
```

The queries use SQLite date functions. The header of `02_Analysis_Queries.sql` lists the MySQL and PostgreSQL equivalents.

### 3. Review the SQL Outputs
Inspect the 16 result files in `SQL Output/`.

### 4. Open the Dashboards
Open the workbook in `Excel Dashboard/` with Excel, and the HTML file in `Web Dashboard/` with any browser.

### 5. Read the Report
`Documentation/Ecommerce_Sales_Analytics_Report.pdf` is a one-page summary of the findings.

## Limitations

- **Synthetic dataset:** The data is a generated practice dataset, so figures such as the 94.6% repeat rate are not realistic.
- **Data quality quirks:** 2,161 orders ship to a different city than the customer's home city, and 439 orders precede the customer's join date. They are documented and left unchanged.
- **Gross profit:** Based on product cost only; shipping, returns handling and marketing costs are not available.
- **Revenue definition:** Shipped orders count as revenue, and some may still be returned.
- **Discount finding:** Units per line are flat across discount levels, but this is observational, not an experiment.
- **Time coverage:** 2025 has ten months; November and December have two years of data.
- **RFM ties:** Many customers share the same order count, so `NTILE` splits ties arbitrarily (broken by customer ID).
- **Interpretation:** Findings describe patterns in this dataset and should not be generalized to all e-commerce.

## Author

**Your Name**
**Anurag Tijare**


**E-Commerce Sales & Customer Analytics**
SQL • Excel • Window Functions • RFM • Business Insights
