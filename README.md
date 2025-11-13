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

For cycle-specific and reproducible HEI computation across all available NHANES–FPED pairs, see **Option 3** below.

<!-- ## Option 2 — `hei` R Package
- Based on **HEI-2005** methodology.  
- Designed for **NHANES 2005–2014** cycles, which correspond to FPED releases from 2005–2006 through 2013–2014.  
- **Assumes consistent FPED variable structure across waves** — however, in reality, FPED variable names, available components, and unit definitions (e.g., cup-equivalents vs gram-equivalents, or how legumes and solid fats are classified) have evolved slightly across releases.  
- Because of these changes, using the same code for all years may produce minor inconsistencies in some component scores (especially for *Legumes*, *Dairy*, and *Solid Fats*).  
- The package does **not  adapt** to these FPED updates, so analysts should manually verify that variable names in their FPED dataset match the expected ones in the code before running HEI calculations.

**Pros:** Easy for older datasets.  
**Cons:** Outdated; not compatible with HEI-2020 or FPED 2017+; cannot handle missing recall days. --> 

---
## Option 2 — `hei2020.R` (under development in this repo)

This option provides an R-based function to compute **HEI-2020** scores directly from NHANES and FPED files.

### How It Works
You specify the desired NHANES wave (for example, `"1314"` for 2013–2014).  
The function automatically locates and harmonizes the corresponding FPED files, computes the 13 HEI-2020 components, and outputs per-person scores.

### Key Features
- Implements the **HEI-2020** scoring system (13 components per 1,000 kcal).  
- Automatically averages across recall days when two reliable recalls are available, or uses a single day if only one is valid.  
- Corrects **added sugars conversion**:  
  - In FPED, `ADD_SUGARS` is expressed in **teaspoon-equivalents (tsp-eq)** — *not* grams or kilocalories.  
  - HEI-2020 requires the **percent of total energy from added sugars**, so tsp-eq values are converted to kilocalories.  
  - The official SAS macro uses a rounded conversion of **16 kcal per tsp**, while this R implementation applies the more accurate **16.8 kcal per tsp** (4.2 g × 4 kcal/g) for improved precision.

### Requirements
- Matching **FPED `.sas7bdat` files** for the selected NHANES cycle.  
- A local R environment with the `dplyr` and `haven` packages installed.  



### Available FPED Versions

The following FPED datasets correspond to their NHANES cycles and file names:

| NHANES Wave | FPED Version | FPED Day 1 File | FPED Day 2 File |
|--------------|---------------|----------------|----------------|
| 2017–March 2020 Pandemic | FPED 2017–2018 | `fped_dr1tot_1718.sas7bdat` | `fped_dr2tot_1718.sas7bdat` |
| 2017–2018 | FPED 2017–2018 | `fped_dr1tot_1718.sas7bdat` | `fped_dr2tot_1718.sas7bdat` |
| 2015–2016 | FPED 2015–2016 | `fped_dr1tot_1516.sas7bdat` | `fped_dr2tot_1516.sas7bdat` |
| 2013–2014 | FPED 2013–2014 | `fped_dr1tot_1314.sas7bdat` | `fped_dr2tot_1314.sas7bdat` |
| 2011–2012 | FPED 2011–2012 | `fped_dr1tot_1112.sas7bdat` | `fped_dr2tot_1112.sas7bdat` |
| 2009–2010 | FPED 2009–2010 | `fped_dr1tot_0910.sas7bdat` | `fped_dr2tot_0910.sas7bdat` |
| 2007–2008 | FPED 2007–2008 | `fped_dr1tot_0708.sas7bdat` | `fped_dr2tot_0708.sas7bdat` |
| 2005–2006 | FPED 2005–2006 | `fped_dr1tot_0506.sas7bdat` | `fped_dr2tot_0506.sas7bdat` |

All FPED files are available from the  
[USDA ARS Food Patterns Equivalents Database (FPED)](https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/beltsville-human-nutrition-research-center/food-surveys-research-group/docs/fped-databases/)



## R Implementation

```r
source("hei2020.R")

# Compute HEI-2020 scores for NHANES 2017–2018
hei_1718 <- compute_hei2020(
  cycle = "1718",
  base_dir = "~/Documents/HEI",
  cache_rds = TRUE
)

# Extract only SEQN and total score
hei_total_1718 <- hei_1718 %>%
  select(SEQN, HEI2020_TOTAL_SCORE)

# Print results
print(hei_total_1718)

# Example output
# A tibble: 7,125 × 2
#     SEQN HEI2020_TOTAL_SCORE
#    <dbl>               <dbl>
#  1 93704                58.4
#  2 93705                44.0
#  3 93706                42.7
#  4 93707                34.3
#  5 93708                48.2
#  6 93711                63.2
#  7 93712                49.4
#  8 93713                45.3
#  9 93714                36.9
# 10 93715                26.4
#  ! 7,115 more rows
```
