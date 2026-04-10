-- Import & explore 

--Creating the empty table and columns with asigned appropriate data types, where we will upload the csv dataset file
CREATE TABLE cancer_variants (
    Chromosome          VARCHAR(10),
    Position            BIGINT,
    Gene                VARCHAR(50),
    Variant_Type        VARCHAR(50),
    Population_AF       NUMERIC(10,6),
    CADD_Score          NUMERIC(8,2),
    SIFT                VARCHAR(20),
    PolyPhen            VARCHAR(30),
    Clinical_Significance VARCHAR(50)
);

--Checking the table content
SELECT * FROM cancer_variants
LIMIT 10;

--Checking for duplicates
SELECT 
    Chromosome, Position, Gene, Variant_Type, 
    Population_AF, CADD_Score, SIFT, PolyPhen, Clinical_Significance,
    COUNT(*) AS duplicate_count
FROM cancer_variants
GROUP BY 
    Chromosome, Position, Gene, Variant_Type, 
    Population_AF, CADD_Score, SIFT, PolyPhen, Clinical_Significance
HAVING COUNT(*) > 1;

--Checking null values
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(Chromosome)             AS nulls_chromosome,
    COUNT(*) - COUNT(Position)               AS nulls_position,
    COUNT(*) - COUNT(Gene)                   AS nulls_gene,
    COUNT(*) - COUNT(Variant_Type)           AS nulls_variant_type,
    COUNT(*) - COUNT(Population_AF)          AS nulls_population_af,
    COUNT(*) - COUNT(CADD_Score)             AS nulls_cadd_score,
    COUNT(*) - COUNT(SIFT)                   AS nulls_sift,
    COUNT(*) - COUNT(PolyPhen)               AS nulls_polyphen,
    COUNT(*) - COUNT(Clinical_Significance)  AS nulls_clinical_significance
FROM cancer_variants;


-- Data cleaning

-- As I previously checked the data for null or duplicated values,
-- and there were no such conditions found, therefore, there is no need to include this step in the data cleaning part

-- Fixing the column headers' names from capitalisation to lowercase
ALTER TABLE cancer_variants RENAME COLUMN "Chromosome" TO chromosome;
ALTER TABLE cancer_variants RENAME COLUMN "Position" TO position;
ALTER TABLE cancer_variants RENAME COLUMN "Gene" TO gene;
ALTER TABLE cancer_variants RENAME COLUMN "Variant_Type" TO variant_type;
ALTER TABLE cancer_variants RENAME COLUMN "Population_AF" TO population_af;
ALTER TABLE cancer_variants RENAME COLUMN "CADD_Score" TO cadd_score;
ALTER TABLE cancer_variants RENAME COLUMN "SIFT" TO sift;
ALTER TABLE cancer_variants RENAME COLUMN "PolyPhen" TO polyphen;
ALTER TABLE cancer_variants RENAME COLUMN "Clinical_Significance" TO clinical_significance;

-- Checking the unique values and value consistency in categorical columns
SELECT DISTINCT clinical_significance FROM cancer_variants;
SELECT DISTINCT variant_type FROM cancer_variants;
SELECT DISTINCT sift FROM cancer_variants;
SELECT DISTINCT polyphen FROM cancer_variants;

-- Dataset Overview

-- The following queries explore the basic structure and distribution of the dataset.
-- Note: this dataset is synthetically generated for machine learning purposes,
-- so distributions reflect artificial balance rather than real clinical patterns.
-- These queries establish a baseline understanding before deeper analysis.

-- 1. Which genes have the highest number of recorded variants — and should be prioritized for further research?
SELECT 
	gene, 
	COUNT(variant_type) AS variant_type_nmbr
FROM cancer_variants
GROUP BY gene
ORDER BY variant_type_nmbr DESC
LIMIT 10;

-- 2. What types of variants (Missense, Frameshift, Nonsense etc.) are most commonly observed across our dataset?
SELECT 
	variant_type, 
	COUNT(variant_type) AS variant_type_nmbr
FROM cancer_variants
GROUP BY variant_type
ORDER BY variant_type_nmbr DESC;

-- 3. What is the breakdown of clinical significance across all variants, 
-- how many are Pathogenic, Likely Pathogenic, Benign, and VUS (Variants of Uncertain Significance)?
SELECT 
    clinical_significance,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM cancer_variants
GROUP BY clinical_significance
ORDER BY total DESC;

-- Data Analysis

-- 4. Conflicting signals: which variants are classified as Benign by clinicians but flagged as deleterious by both SIFT and PolyPhen? 
-- And the opposite — Pathogenic variants that both tools rated as benign/tolerated?
WITH clinical_benign_cnt AS (
    SELECT
        gene,
        sift,
        polyphen,
        clinical_significance,
        COUNT(*) AS total_variants
    FROM cancer_variants
    WHERE clinical_significance = 'Benign'
    AND sift = 'deleterious'
    AND polyphen = 'probably_damaging'
    GROUP BY gene, sift, polyphen, clinical_significance
),
clinical_pathogenic_cnt AS (
    SELECT
        gene,
        sift,
        polyphen,
        clinical_significance,
        COUNT(*) AS total_variants
    FROM cancer_variants
    WHERE clinical_significance = 'Pathogenic'
    AND sift = 'tolerated'
    AND polyphen = 'benign'
    GROUP BY gene, sift, polyphen, clinical_significance
)
SELECT * FROM clinical_benign_cnt
UNION ALL
SELECT * FROM clinical_pathogenic_cnt
ORDER BY clinical_significance, total_variants DESC;
-- Finding: genes with the most conflicts in one direction tend to have 
-- fewer in the opposite direction.
-- For example, PTEN has the highest count of variants flagged as dangerous
-- by SIFT and PolyPhen but Benign clinically (30 cases),
-- while ALK leads the opposite — safe by both tools but Pathogenic clinically (27 cases).
-- This suggests that for certain genes, computational tools and clinical 
-- classification consistently disagree — just in different directions.

-- 5. Which variants have been flagged as damaging by both SIFT and PolyPhen simultaneously, our highest-confidence risk cases?

-- Flagging variants where SIFT confirms deleterious impact
-- and PolyPhen indicates either probable or possible damage
-- both probably_damaging and possibly_damaging are included
-- as both signal potential clinical concern
SELECT 
	gene,
	variant_type,
	sift,
	polyphen,
	clinical_significance,
	cadd_score
FROM cancer_variants
WHERE sift = 'deleterious'
AND polyphen IN ('probably_damaging', 'possibly_damaging')
ORDER BY cadd_score DESC
LIMIT 20;
-- Interesting finding: some variants flagged as damaging by both SIFT and PolyPhen
-- still show Benign clinical significance. This reminds us that computational tools
-- are a starting point, not a final answer — real clinical data doesn't always
-- match what the algorithms predict

-- 6. Which genes have the highest average CADD score — indicating the most severe mutations at a gene level?
SELECT 
	gene,
	COUNT(*) AS total_variants,
	ROUND(AVG(cadd_score), 2) AS avg_cadd_score
FROM cancer_variants
GROUP BY gene
ORDER BY avg_cadd_score DESC
LIMIT 10;
-- Interesting: IDH1 has the highest average CADD score, meaning its mutations
-- tend to be more severe on average compared to other genes
-- Also worth noting: the scores across all top 10 genes are quite close (19.91 to 20.77),
-- so no single gene stands out dramatically, severity is spread fairly evenly

-- 7. For each gene, what is the position range (MIN and MAX position) 
-- of its variants — how spread across the chromosome are they?

-- First checking how many chromosomes each gene appears on
SELECT 
    gene, 
    COUNT(DISTINCT chromosome) AS chromosome_count
FROM cancer_variants
GROUP BY gene
HAVING COUNT(DISTINCT chromosome) > 1
ORDER BY chromosome_count DESC;

-- Finding: all 20 genes appear across all 22 chromosomes,
-- which is biologically impossible — a gene has one fixed chromosomal location.
-- This confirms the dataset is synthetically generated.
-- As a result, chromosome and position based analysis cannot produce
-- meaningful biological insights and this question is excluded from further analysis.

-- 8. What is the average CADD score per variant type and clinical significance combination — and how does severity differ across these groups?
SELECT
    variant_type,
    clinical_significance,
    COUNT(*) AS total_variants,
    ROUND(AVG(cadd_score), 3) AS avg_cadd_score,
    ROUND(MIN(cadd_score), 3) AS min_cadd_score,
    ROUND(MAX(cadd_score), 3) AS max_cadd_score
FROM cancer_variants
GROUP BY variant_type, clinical_significance
ORDER BY avg_cadd_score DESC;


-- 9. For each variant type, what percentage end up Pathogenic vs Benign vs VUS — which variant type is the most clinically dangerous?
SELECT
    variant_type,
    ROUND(COUNT(CASE WHEN clinical_significance = 'Pathogenic' THEN 1 END) * 100.0 / COUNT(*), 2) AS pathogenic_pct,
    ROUND(COUNT(CASE WHEN clinical_significance = 'Likely_pathogenic' THEN 1 END) * 100.0 / COUNT(*), 2) AS likely_pathogenic_pct,
    ROUND(COUNT(CASE WHEN clinical_significance = 'Benign' THEN 1 END) * 100.0 / COUNT(*), 2) AS benign_pct,
    ROUND(COUNT(CASE WHEN clinical_significance = 'VUS' THEN 1 END) * 100.0 / COUNT(*), 2) AS vus_pct
FROM cancer_variants
GROUP BY variant_type
ORDER BY pathogenic_pct DESC;
-- Finding: all variant types show nearly identical clinical significance distributions,
-- with each category (Pathogenic, Likely Pathogenic, Benign, VUS) sitting around 25%.
-- This is consistent with the dataset being synthetically generated —
-- in real clinical data, Frameshift and Nonsense variants would typically 
-- show significantly higher Pathogenic rates than Synonymous variants.

	

-- 10. Full risk summary per gene: total variants, pathogenic count, 
-- avg CADD score, and most common variant type — ranked by risk
WITH gene_stats AS (
    SELECT
        gene,
        COUNT(*) AS total_variants,
        COUNT(CASE WHEN clinical_significance = 'Pathogenic' THEN 1 END) AS pathogenic_count,
        COUNT(CASE WHEN clinical_significance = 'Likely_pathogenic' THEN 1 END) AS likely_pathogenic_count,
        ROUND(AVG(cadd_score), 2) AS avg_cadd_score
    FROM cancer_variants
    GROUP BY gene
),
most_common_variant AS (
    SELECT
        gene,
        variant_type,
        ROW_NUMBER() OVER (
            PARTITION BY gene
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM cancer_variants
    GROUP BY gene, variant_type
)
SELECT
    g.gene,
    g.total_variants,
    g.pathogenic_count,
    g.likely_pathogenic_count,
    g.avg_cadd_score,
    m.variant_type AS most_common_variant_type,
    RANK() OVER (ORDER BY g.pathogenic_count DESC) AS risk_rank
FROM gene_stats g
JOIN most_common_variant m 
    ON g.gene = m.gene 
    AND m.rn = 1
ORDER BY risk_rank;
-- Finding: VHL ranks #1 in overall risk with the highest pathogenic count (146),
-- followed closely by EGFR (142) and KRAS/KIT tied at 133.
-- However the differences between genes are small across the board —
-- again reflecting the synthetic nature of the dataset where no single gene
-- dramatically dominates in risk.
-- In a real dataset, genes like TP53 and BRCA1 would typically rank much higher.

-- 11. Does mutation severity (CADD score) relate to how common a variant is in the population 
-- and does clinical significance follow any pattern across these two dimensions?

SELECT 
	gene,
	ROUND(population_af, 3) AS population_af,
	cadd_score,
	clinical_significance
FROM cancer_variants
ORDER BY cadd_score DESC;
