
[![Cancer Research Software Hub](https://img.shields.io/badge/Back_to-Hub-blue)](https://github.com/younghhk/NCI)

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


---

# Available Options to Compute HEI-2020 Scores

## Option 1 — Official SAS Macro

**Sources**  
- [NCI HEI Scoring SAS Macros (official site)](https://epi.grants.cancer.gov/hei/sas-code.html)  
- [Direct download: HEI-2020 Scoring Macro (ZIP)](https://epi.grants.cancer.gov/hei/hei2020-score-macro.zip)  
- [HEI-2020 Scoring Method Documentation](https://epi.grants.cancer.gov/hei/hei-scoring-method.html)

Each NHANES cycle must be paired with its **corresponding FPED (Food Patterns Equivalents Database)**, as food codes and variable definitions differ across cycles.

**Important Note**  
The NCI HEI-2020 SAS Macro was developed and validated for **NHANES 2017–2018** only.  
While the HEI-2020 algorithm can theoretically be applied to earlier NHANES waves, the official macro itself is **not guaranteed to work correctly** with older FPED structures (e.g., 2013–2014 or 2011–2012).  

For cycle-specific and reproducible HEI computation across all available NHANES–FPED pairs, see **Option 2** below.


All FPED files are available from the  
[USDA ARS Food Patterns Equivalents Database (FPED)](https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/beltsville-human-nutrition-research-center/food-surveys-research-group/docs/fped-databases/)


<!-- ## Option 2 — `hei` R Package
- Based on **HEI-2005** methodology.  
- Designed for **NHANES 2005–2014** cycles, which correspond to FPED releases from 2005–2006 through 2013–2014.  
- **Assumes consistent FPED variable structure across waves** — however, in reality, FPED variable names, available components, and unit definitions (e.g., cup-equivalents vs gram-equivalents, or how legumes and solid fats are classified) have evolved slightly across releases.  
- Because of these changes, using the same code for all years may produce minor inconsistencies in some component scores (especially for *Legumes*, *Dairy*, and *Solid Fats*).  
- The package does **not  adapt** to these FPED updates, so analysts should manually verify that variable names in their FPED dataset match the expected ones in the code before running HEI calculations.

**Pros:** Easy for older datasets.  
**Cons:** Outdated; not compatible with HEI-2020 or FPED 2017+; cannot handle missing recall days. --> 

---
## Option 2 — `hei2020.R`

This code provides an `R` function for computing **HEI-2020** scores.

It builds on the functionality of the `heiscore` package but extends it by also
scoring participants who have **only one** valid dietary recall (Day 1 *or* Day 2).


## R Implementation

```r
source("hei2020.R")
hei <- compute_hei2020_anyday("1718")

dim(hei)         # number of people who have >=1 day AND all components non-missing
head(hei)

# Just SEQN + total score if you want:
hei_total <- hei %>% select(SEQN, HEI2020_TOTAL_SCORE)
head(hei_total)

> # Just SEQN + total score if you want:
> hei_total <- hei %>% select(SEQN, HEI2020_TOTAL_SCORE)
> head(hei_total)
   SEQN HEI2020_TOTAL_SCORE
1 93704            65.76993
2 93705            44.50729
3 93706            44.48747
4 93707            41.31504
5 93708            52.74016
6 93710            58.86168

> compare_heiscore_vs_hei2020("1718")
Total SEQN in hei2020 output:         7494 
Total SEQN in heiscore output:        6180 
Common SEQN (both):                   6180 
SEQN only in hei2020 (1-day extra):   1314 

=== COMMON SUBJECTS (first 10) ===
    SEQN hei2020_total heiscore_total
1  93704      65.76993       65.76993
2  93705      44.50729       44.50729
3  93707      41.31504       41.31504
4  93708      52.74016       52.74016
5  93711      71.30719       71.30719
6  93712      50.15362       50.15362
7  93713      54.62052       54.62052
8  93714      37.11114       37.11114
9  93715      31.46482       31.46482
10 93716      63.00828       63.00828

=== IN hei2020 ONLY (first 10) ===
    SEQN hei2020_total heiscore_total
1  93706      44.48747             NA
2  93710      58.86168             NA
3  93720      69.40862             NA
4  93748      36.45583             NA
5  93761      60.91797             NA
6  93764      66.23787             NA
7  93765      36.65384             NA
8  93768      60.83761             NA
9  93803      38.50167             NA
10 93804      65.52974             NA
```
## Citation

If you use this HEI-2020 implementation in your work, please cite:

- The original `heiscore` R package (for dataset preprocessing and reference implementation).
- This repository for the extended HEI-2020 scoring that includes one-day recalls:

> Hong (2025). HEI-2020 scoring with expanded NHANES recall coverage (version 1.0.0). GitHub. [https://doi.org/10.5281/zenodo.17596091](https://doi.org/10.5281/zenodo.17596091)
