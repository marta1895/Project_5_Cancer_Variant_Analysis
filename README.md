# Project 5: Cancer Variant Analysis

## Overview
This project explores a cancer variant prioritization dataset using SQL (PostgreSQL / DBeaver) and Tableau. The analysis covers data cleaning, exploratory analysis, and business-driven questions around gene mutation patterns, clinical risk classification, and the reliability of computational prediction tools.
> **Dataset note:** This dataset is synthetically generated for machine learning purposes. Some findings — such as genes appearing across all 22 chromosomes — are not biologically realistic. All queries are written to demonstrate analytical logic rather than draw real clinical conclusions.

---

## Dataset

- **Source:** [Cancer Variant Dataset for Machine Learning — Kaggle](https://www.kaggle.com/datasets/punithpunk/cancer-variant-dataset-for-machine-learning)
- **File:** `cancer_variant_prioritization_dataset.csv`
- **Rows:** 10,000
- **Columns:** 9

| Column | Type | Description |
|---|---|---|
| Chromosome | VARCHAR | Chromosome number (1–22, X, Y) |
| Position | BIGINT | Genomic position of the variant |
| Gene | VARCHAR | Gene name (e.g. BRCA1, TP53) |
| Variant_Type | VARCHAR | Type of mutation (Missense, Frameshift, etc.) |
| Population_AF | NUMERIC | Allele frequency in the population |
| CADD_Score | NUMERIC | Computational score for mutation severity |
| SIFT | VARCHAR | Functional prediction: deleterious / tolerated |
| PolyPhen | VARCHAR | Functional prediction: probably_damaging / possibly_damaging / benign |
| Clinical_Significance | VARCHAR | Clinical label: Pathogenic / Likely_pathogenic / Benign / VUS |

---

## Tools

- **SQL:** PostgreSQL via DBeaver
- **Visualization:** Tableau Public

---

## Project Structure

```
Project_5_Cancer_Variant_Analysis/
│
├── canser_variants_analysis.sql   # All SQL queries with inline comments
├── Cancer_Variants_Analysis.twb   # Tableau workbook
└── README.md
```

---

## What Was Done

### 1. Import & Explore
- Created table with appropriate data types for each column
- Imported CSV via DBeaver import tool
- Checked for nulls → none found
- Checked for duplicates → none found

### 2. Data Cleaning
- Renamed all column headers to lowercase snake_case
- Verified categorical columns for value consistency (no typos or unexpected values found)

### 3. Dataset Overview (EDA)
- Identified the top genes by variant count
- Explored variant type distribution across the dataset
- Broke down clinical significance categories with percentages using a window function

### 4. Data Analysis — 8 Business Questions

| # | Question |
|---|---|
| 4 | Which genes show conflicting signals between computational tools and clinical classification? |
| 5 | Which variants are flagged as damaging by both SIFT and PolyPhen simultaneously? |
| 6 | Which genes have the highest average CADD score? |
| 7 | How many chromosomes does each gene appear on? (data quality check) |
| 8 | How does CADD score differ across variant type and clinical significance combinations? |
| 9 | For each variant type, what percentage end up Pathogenic vs Benign vs VUS? |
| 10 | Full risk summary per gene — total variants, pathogenic count, avg CADD score, most common variant type, ranked by risk |
| 11 | Does mutation severity relate to population frequency across clinical significance groups? |

---

## Key Findings

**1. Computational tools and clinical classification frequently disagree**
Some variants flagged as damaging by both SIFT and PolyPhen are still labeled Benign clinically. This is most visible in PTEN (30 conflicting cases) and ALK (27 cases in the opposite direction). Computational tools are a starting point, not a final answer — real clinical evidence doesn't always match algorithmic predictions.

**2. Mutation severity does not predict pathogenic frequency**
IDH1 has the highest average CADD score (20.77) but ranks near the bottom in pathogenic variant count. VHL and EGFR show the opposite — high pathogenic counts but lower severity scores. Higher molecular severity does not automatically mean a gene produces more pathogenic variants.

**3. Synthetic data limitations surfaced through analysis**
Two synthetic data artifacts were identified during analysis: all 20 genes appear across all 22 chromosomes (biologically impossible), and all variant types show identical ~25% distributions across clinical significance categories. In real clinical data, Frameshift and Nonsense variants would typically show much higher Pathogenic rates than Synonymous variants.

---

## Dataset Limitations

This dataset was designed for machine learning classification tasks, not biological research. Key limitations discovered during analysis:

- Every gene appears on all 22 chromosomes — biologically impossible
- Clinical significance is artificially balanced at ~25% per category across all variant types
- No meaningful separation between rare and common variants in terms of pathogenicity (49.52% vs 50.13%)

These limitations do not affect the SQL techniques demonstrated but should be considered when interpreting any findings.

---

## Tableau Dashboard

The dashboard includes 4 charts:

1. **Gene Risk Summary** — horizontal bar chart of top 10 genes by pathogenic variant count
2. **Conflicting Risk Signals by Gene** — grouped bar chart showing computational vs clinical disagreements for top 6 genes
3. **Mutation Severity vs Pathogenic Frequency** — scatter plot of avg CADD score vs pathogenic count per gene
4. **Population Frequency vs Mutation Severity** — scatter plot of population AF vs CADD score, colored by clinical significance

> Tableau Public link: *(add after publishing)*

---

## How to Run

1. Create a PostgreSQL database in DBeaver
2. Run the `CREATE TABLE` statement at the top of `canser_variants_analysis.sql`
3. Import `cancer_variant_prioritization_dataset.csv` via right-click → Import Data
4. Run queries sequentially — each section is clearly commented
