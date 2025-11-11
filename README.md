> 🧬 **For additional cancer research software and tools**, visit  
> [Cancer Research Software Repository](https://github.com/younghhk/NCI)

---
# Healthy Eating Index (HEI)

## Overview
The **Healthy Eating Index (HEI)**, developed by the **U.S. Department of Agriculture (USDA)** and the **National Cancer Institute (NCI)**, measures how well a set of foods—an individual’s diet, a menu, or a population intake—aligns with the **Dietary Guidelines for Americans (DGA)**.

### Purpose and Scoring
- **Range:** 0–100 (higher = better adherence)
- **Components:**
  - **Adequacy:** foods to encourage (e.g., vegetables, whole grains)
  - **Moderation:** foods to limit (e.g., added sugars, sodium)
- **Density-based approach:** calculated **per 1,000 kcal**, allowing comparison across age, sex, and energy levels.

---

## Why the HEI Matters
- **Surveillance:** Tracks population diet quality over time (e.g., mean U.S. adult HEI-2020 ≈ 58/100).  
- **Health outcomes:** Higher HEI scores are associated with lower risks of cardiovascular disease, diabetes, stroke, and all-cause mortality.  
- **Policy and programs:** Used to evaluate nutrition initiatives such as SNAP and WIC.

---

## Evolution of the HEI
| Version | Corresponding DGA | Key Distinctions |
|:--|:--|:--|
| **HEI-2020** (current) | 2020–2025 | Retains 13 components from HEI-2015; adds *HEI-Toddlers-2020* (ages 12–23 mo, excludes Added Sugars). |
| **HEI-2015** | 2015–2020 | Introduced a dedicated *Added Sugars* component (<10% of kcal). |
| **HEI-2010** | 2010 | Updated “Empty Calories” and “Seafood & Plant Proteins.” |
| **HEI-1995** | 1995 | Included a “Variety” component (later integrated into other groups). |


---

## The Role of the Food Patterns Equivalents Database (FPED)
**FPED** translates foods reported in NHANES 24-hour recalls (e.g., *pizza*, *yogurt with granola*) into **USDA food pattern components** (e.g., Refined Grains, Total Protein Foods).

- **Problem:** NHANES reports foods “as eaten.”  
- **Solution:** FPED decomposes each food into 37 standardized USDA components.  
- **Why it matters:** HEI cannot be calculated directly from recall data; FPED provides the link between raw foods and HEI scoring.

> **FPED = the translator** between NHANES recall data and HEI scoring.

---

# Available Options to Compute HEI Scores

## Option 1 — SAS Macro (Official)
**Source:** [NCI HEI SAS Macros](https://epi.grants.cancer.gov/hei/sas-code.html)

- Requires matching **FPED** `.sas7bdat` files for each NHANES cycle.  

**Pros:** Official, validated by USDA/NCI  
**Cons:** SAS-only; requires local extraction of FPED data

---

## Option 2 — `hei` R Package
- Based on **HEI-2005** methodology.  
- Designed for **NHANES 2005–2014** cycles, which correspond to FPED releases from 2005–2006 through 2013–2014.  
- **Assumes consistent FPED variable structure across waves** — however, in reality, FPED variable names, available components, and unit definitions (e.g., cup-equivalents vs gram-equivalents, or how legumes and solid fats are classified) have evolved slightly across releases.  
- Because of these changes, using the same code for all years may produce minor inconsistencies in some component scores (especially for *Legumes*, *Dairy*, and *Solid Fats*).  
- The package does **not  adapt** to these FPED updates, so analysts should manually verify that variable names in their FPED dataset match the expected ones in the code before running HEI calculations.

**Pros:** Easy for older datasets.  
**Cons:** Outdated; not compatible with HEI-2020 or FPED 2017+; cannot handle missing recall days.

---

## Option 3 — `hei2020.R` (under development in this repo)
An **R-based HEI-2020 pipeline** for NHANES 2017–2018.

### Key Features
- Uses **FPED 2017–2018** (Day 1 & Day 2 totals).  
- Implements **HEI-2020** scoring logic (13 components per 1,000 kcal).  
- Replicates NCI’s official SAS macro entirely in **R** using `haven` and `dplyr`.  
- Computes 13 component scores and the total HEI score (0–100).  
- Automatically averages across recall days if two reliable days are available, or uses one day when only a single recall is valid.  
- Adjusts for **added sugars conversion**:  
  - In FPED, `ADD_SUGARS` is expressed in **teaspoon-equivalents (tsp-eq)** — *not* grams or kilocalories.  
  - HEI-2020 requires **percent of total energy from added sugars**, so tsp-eq values are converted to kcal.  
  - The **official SAS macro** uses a rounded factor of **16 kcal per tsp**, while this `hei2020.R` script applies the **chemically accurate conversion** of **16.8 kcal per tsp** (4.2 g × 4 kcal/g) for greater precision.

## R Implementation

```r
# Run the HEI-2020 workflow
source("HEI2020.R")

# Extract total HEI-2020 scores per participant
HEI_total <- HEI2020 %>%
  dplyr::select(SEQN, HEI2020_TOTAL_SCORE)

# View results
print(HEI_total)

# A tibble: 7,125 × 2
    SEQN HEI2020_TOTAL_SCORE
   <dbl>               <dbl>
 1 93704                58.8
 2 93705                44.5
 3 93706                42.7
 4 93707                34.8
 5 93708                48.4
 6 93711                63.5
 7 93712                49.8
 8 93713                45.8
 9 93714                37.1
10 93715                27.1

write.csv(HEI_total, "hei2020_total_scores.csv", row.names = FALSE)
```

