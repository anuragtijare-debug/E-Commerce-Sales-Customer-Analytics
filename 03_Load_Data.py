"""Build ecommerce.db (SQLite) in the repository root from the schema and the Dataset/ CSV files.

Run from anywhere:  python SQL/03_Load_Data.py
Then run the analysis:  sqlite3 ecommerce.db < SQL/02_Analysis_Queries.sql
"""
import csv
import os
import sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DB = os.path.join(ROOT, "ecommerce.db")
TABLES = ["customers", "products", "orders", "order_items"]  # parent tables first

if os.path.exists(DB):
    os.remove(DB)

con = sqlite3.connect(DB)
con.execute("PRAGMA foreign_keys = ON")
with open(os.path.join(HERE, "01_Schema.sql")) as f:
    con.executescript(f.read())

for table in TABLES:
    with open(os.path.join(ROOT, "Dataset", f"{table}.csv"), newline="") as f:
        rows = list(csv.reader(f))
    header, body = rows[0], rows[1:]
    marks = ",".join("?" * len(header))
    con.executemany(f"INSERT INTO {table} ({','.join(header)}) VALUES ({marks})", body)
    print(f"{table}: {len(body)} rows loaded")

con.commit()
print("Foreign key violations:", len(con.execute("PRAGMA foreign_key_check").fetchall()))
con.close()
