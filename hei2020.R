library(dplyr)
library(heiscore)

# ------------------------------------------------------------------------------
# Compute HEI-2020 scores using heiscore::selectDataset()
# 
# Differences vs heiscore::score():
#   * A person is kept if they have EITHER day 1 or day 2 (at least one recall),
#     not just those with valid 2-day weights.
#   * A person is dropped if ANY of the 13 component scores is missing.
#
# years: NHANES cycle string as used by heiscore (e.g., "1718")
#
# Returns: tibble with SEQN, 13 component scores, and HEI2020_TOTAL_SCORE
# ------------------------------------------------------------------------------

compute_hei2020_anyday <- function(years = "1718") {
  
  # 1. Get preprocessed NHANES + FPED from heiscore
  ds <- heiscore::selectDataset(years = years)
  # ds has per-day variables like DR1TKCAL, DR2TKCAL,
  # DR1_VTOTALLEG, DR2_VTOTALLEG, DR1_PFALLPROTLEG, etc.
  
  # Helper: aggregate day 1 + day 2
  # - If both days are NA -> NA
  # - If only one day is available -> use that day's value
  # - If both available -> sum
  agg_2days <- function(x1, x2) {
    ifelse(is.na(x1) & is.na(x2),
           NA_real_,
           dplyr::coalesce(x1, 0) + dplyr::coalesce(x2, 0))
  }
  
  # 2. Per-person totals across days
  ds2 <- ds %>%
    mutate(
      # Total energy (kcal)
      KCAL_tot = agg_2days(DR1TKCAL, DR2TKCAL),
      
      # HEI component intakes (using heiscore's legume-adjusted variables)
      VTOTALLEG_tot   = agg_2days(DR1_VTOTALLEG,     DR2_VTOTALLEG),
      VDRKGRLEG_tot   = agg_2days(DR1_VDRKGRLEG,     DR2_VDRKGRLEG),
      F_TOTAL_tot     = agg_2days(DR1T_F_TOTAL,      DR2T_F_TOTAL),
      FWHOLEFRT_tot   = agg_2days(DR1_FWHOLEFRT,     DR2_FWHOLEFRT),
      G_WHOLE_tot     = agg_2days(DR1T_G_WHOLE,      DR2T_G_WHOLE),
      D_TOTAL_tot     = agg_2days(DR1T_D_TOTAL,      DR2T_D_TOTAL),
      PFALLPROT_tot   = agg_2days(DR1_PFALLPROTLEG,  DR2_PFALLPROTLEG),
      PFSEAPLANT_tot  = agg_2days(DR1_PFSEAPLANTLEG, DR2_PFSEAPLANTLEG),
      G_REFINED_tot   = agg_2days(DR1T_G_REFINED,    DR2T_G_REFINED),
      SODI_tot        = agg_2days(DR1TSODI,          DR2TSODI),
      ADD_SUGARS_tot  = agg_2days(DR1T_ADD_SUGARS,   DR2T_ADD_SUGARS),
      SFAT_tot        = agg_2days(DR1TSFAT,          DR2TSFAT),
      MONOPOLY_tot    = agg_2days(DR1_MONOPOLY,      DR2_MONOPOLY)
    ) %>%
    # Require at least some energy
    filter(!is.na(KCAL_tot) & KCAL_tot > 0)
  
  # 3. Densities and ratios
  ds2 <- ds2 %>%
    mutate(
      k1000 = KCAL_tot / 1000,
      
      # per 1000 kcal (adequacy components)
      d_VTOTALLEG   = VTOTALLEG_tot   / k1000,
      d_VDRKGRLEG   = VDRKGRLEG_tot   / k1000,
      d_F_TOTAL     = F_TOTAL_tot     / k1000,
      d_FWHOLEFRT   = FWHOLEFRT_tot   / k1000,
      d_G_WHOLE     = G_WHOLE_tot     / k1000,
      d_D_TOTAL     = D_TOTAL_tot     / k1000,
      d_PFALLPROT   = PFALLPROT_tot   / k1000,
      d_PFSEAPLANT  = PFSEAPLANT_tot  / k1000,
      d_G_REFINED   = G_REFINED_tot   / k1000,
      
      # Sodium: work in GRAMS per 1000 kcal
      # SODI_tot is mg; SODI_tot / KCAL_tot is numerically g per 1000 kcal
      d_SODI_g      = SODI_tot / KCAL_tot,
      
      # Fatty acid ratio (MUFA+PUFA / SFA)
      fatty_ratio   = ifelse(is.na(MONOPOLY_tot) | is.na(SFAT_tot) | SFAT_tot <= 0,
                             NA_real_,
                             MONOPOLY_tot / SFAT_tot),
      
      # Added sugars kcal: 16 kcal per teaspoon equivalent (4 g * 4 kcal/g)
      ADDSUG_KCAL   = ADD_SUGARS_tot * 16,
      pct_satfat    = (SFAT_tot * 9) / KCAL_tot * 100,
      pct_addsug    = ADDSUG_KCAL / KCAL_tot * 100
    )
  
  # 4. Linear scoring helper
  lin_score <- function(x, xmin, xmax, smin, smax) {
    slope <- (smax - smin) / (xmax - xmin)
    val   <- smin + slope * (x - xmin)
    val   <- pmin(pmax(val, smin), smax)
    ifelse(is.na(x), NA_real_, val)
  }
  
  # 5. Component scores
  res <- ds2 %>%
    mutate(
      # Adequacy components
      HEI2020_TOTALVEG       = lin_score(d_VTOTALLEG,   0,   1.1, 0,  5),
      HEI2020_GREEN_AND_BEAN = lin_score(d_VDRKGRLEG,   0,   0.2, 0,  5),
      HEI2020_TOTALFRUIT     = lin_score(d_F_TOTAL,     0,   0.8, 0,  5),
      HEI2020_WHOLEFRUIT     = lin_score(d_FWHOLEFRT,   0,   0.4, 0,  5),
      HEI2020_WHOLEGRAIN     = lin_score(d_G_WHOLE,     0,   1.5, 0, 10),
      HEI2020_TOTALDAIRY     = lin_score(d_D_TOTAL,     0,   1.3, 0, 10),
      HEI2020_TOTPROT        = lin_score(d_PFALLPROT,   0,   2.5, 0,  5),
      HEI2020_SEAPLANT_PROT  = lin_score(d_PFSEAPLANT,  0,   0.8, 0,  5),
      HEI2020_FATTYACID      = lin_score(fatty_ratio, 1.2,   2.5, 0, 10),
      
      # Moderation components
      # sodium: 2.0 g (0 points) to 1.1 g (10 points) per 1000 kcal
      HEI2020_REFINEDGRAIN   = lin_score(d_G_REFINED,  4.3,  1.8, 0, 10),
      HEI2020_SODIUM         = lin_score(d_SODI_g,     2.0,  1.1, 0, 10),
      HEI2020_SFAT           = lin_score(pct_satfat,     16,   8, 0, 10),
      HEI2020_ADDSUG         = lin_score(pct_addsug,     26, 6.5, 0, 10)
    ) %>%
    mutate(
      HEI2020_TOTAL_SCORE =
        HEI2020_TOTALVEG + HEI2020_GREEN_AND_BEAN + HEI2020_TOTALFRUIT +
        HEI2020_WHOLEFRUIT + HEI2020_WHOLEGRAIN + HEI2020_TOTALDAIRY +
        HEI2020_TOTPROT + HEI2020_SEAPLANT_PROT + HEI2020_FATTYACID +
        HEI2020_REFINEDGRAIN + HEI2020_SODIUM + HEI2020_SFAT + HEI2020_ADDSUG
    )
  
  # 6. Drop anyone with any missing component
  comp_cols <- c(
    "HEI2020_TOTALVEG", "HEI2020_GREEN_AND_BEAN", "HEI2020_TOTALFRUIT",
    "HEI2020_WHOLEFRUIT", "HEI2020_WHOLEGRAIN", "HEI2020_TOTALDAIRY",
    "HEI2020_TOTPROT", "HEI2020_SEAPLANT_PROT", "HEI2020_FATTYACID",
    "HEI2020_REFINEDGRAIN", "HEI2020_SODIUM", "HEI2020_SFAT", "HEI2020_ADDSUG"
  )
  
  res %>%
    filter(if_all(all_of(comp_cols), ~ !is.na(.x))) %>%
    select(SEQN, all_of(comp_cols), HEI2020_TOTAL_SCORE)
}


###
#run
hei <- compute_hei2020_anyday("1718")

dim(hei)         # number of people who have >=1 day AND all components non-missing
head(hei)

# Just SEQN + total score if you want:
hei_total <- hei %>% select(SEQN, HEI2020_TOTAL_SCORE)
head(hei_total)
