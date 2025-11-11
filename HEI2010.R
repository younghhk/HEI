# Packages
library(haven)
library(dplyr)

# --------- USER: set local FPED paths 

fped_dr1_path <- "~/Documents/HEI/fped_dr1tot_1718.sas7bdat"
fped_dr2_path <- "~/Documents/HEI/fped_dr2tot_1718.sas7bdat"

FPED1 <- haven::read_sas(fped_dr1_path)
FPED2 <- haven::read_sas(fped_dr2_path)


# NHANES 2017–2018 nutrient and demo XPT files (downloaded on-the-fly)
dr1tot_xpt <- "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DR1TOT_J.xpt"
dr2tot_xpt <- "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DR2TOT_J.xpt"
demo_xpt   <- "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DEMO_J.xpt"

# --------- Read FPED DR1 & DR2 (per day) ----------
# FPED variables are per 24HR day; keep only fields needed for HEI
FPED1 <- read_sas(fped_dr1_path) %>%
  transmute(
    SEQN,
    DAYREC = 1L,
    F_CITMLB     = DR1T_F_CITMLB,
    F_OTHER      = DR1T_F_OTHER,
    PF_MPS_TOTAL = DR1T_PF_MPS_TOTAL,
    PF_EGGS      = DR1T_PF_EGGS,
    PF_NUTSDS    = DR1T_PF_NUTSDS,
    PF_SOY       = DR1T_PF_SOY,
    PF_SEAFD_HI  = DR1T_PF_SEAFD_HI,
    PF_SEAFD_LOW = DR1T_PF_SEAFD_LOW,
    ADD_SUGARS   = DR1T_ADD_SUGARS,   # teaspoons eq
    SOLID_FATS   = DR1T_SOLID_FATS,   # grams
    V_TOTAL      = DR1T_V_TOTAL,
    V_DRKGR      = DR1T_V_DRKGR,
    V_LEGUMES    = DR1T_V_LEGUMES,
    PF_LEGUMES   = DR1T_PF_LEGUMES,
    F_TOTAL      = DR1T_F_TOTAL,
    G_WHOLE      = DR1T_G_WHOLE,
    D_TOTAL      = DR1T_D_TOTAL,
    G_REFINED    = DR1T_G_REFINED
  )

FPED2 <- read_sas(fped_dr2_path) %>%
  transmute(
    SEQN,
    DAYREC = 2L,
    F_CITMLB     = DR2T_F_CITMLB,
    F_OTHER      = DR2T_F_OTHER,
    PF_MPS_TOTAL = DR2T_PF_MPS_TOTAL,
    PF_EGGS      = DR2T_PF_EGGS,
    PF_NUTSDS    = DR2T_PF_NUTSDS,
    PF_SOY       = DR2T_PF_SOY,
    PF_SEAFD_HI  = DR2T_PF_SEAFD_HI,
    PF_SEAFD_LOW = DR2T_PF_SEAFD_LOW,
    ADD_SUGARS   = DR2T_ADD_SUGARS,   # teaspoons eq
    SOLID_FATS   = DR2T_SOLID_FATS,   # grams
    V_TOTAL      = DR2T_V_TOTAL,
    V_DRKGR      = DR2T_V_DRKGR,
    V_LEGUMES    = DR2T_V_LEGUMES,
    PF_LEGUMES   = DR2T_PF_LEGUMES,
    F_TOTAL      = DR2T_F_TOTAL,
    G_WHOLE      = DR2T_G_WHOLE,
    D_TOTAL      = DR2T_D_TOTAL,
    G_REFINED    = DR2T_G_REFINED
  )

FPED <- bind_rows(FPED1, FPED2)

# --------- Read NHANES nutrients (per day; keep reliable only) ----------
NUT1 <- read_xpt(dr1tot_xpt) %>%
  transmute(
    SEQN,
    DAYREC = 1L,
    DRSTZ  = DR1DRSTZ,
    KCAL   = DR1TKCAL,
    MFAT   = DR1TMFAT,
    PFAT   = DR1TPFAT,
    SFAT   = DR1TSFAT,
    SODI   = DR1TSODI
  ) %>%
  filter(DRSTZ == 1)

NUT2 <- read_xpt(dr2tot_xpt) %>%
  transmute(
    SEQN,
    DAYREC = 2L,
    DRSTZ  = DR2DRSTZ,
    KCAL   = DR2TKCAL,
    MFAT   = DR2TMFAT,
    PFAT   = DR2TPFAT,
    SFAT   = DR2TSFAT,
    SODI   = DR2TSODI
  ) %>%
  filter(DRSTZ == 1)

NUTRIENT <- bind_rows(NUT1, NUT2)

# --------- Read demographics; age filter (>=2 years) ----------
DEMO <- read_xpt(demo_xpt) %>%
  transmute(SEQN, RIDAGEYR) %>%
  filter(RIDAGEYR >= 2)

# --------- Merge FPED + Nutrients by (SEQN, DAYREC), then add DEMO by SEQN ----------
NUTFDPYR <- inner_join(FPED, NUTRIENT, by = c("SEQN","DAYREC"))
COHORT   <- inner_join(DEMO, NUTFDPYR, by = "SEQN")

# --------- Derive variables (legume allocations already included in *_LEG vars) ----------
COHORT <- COHORT %>%
  mutate(
    FWHOLEFRT      = F_CITMLB + F_OTHER,
    MONOPOLY       = MFAT + PFAT,
    VTOTALLEG      = V_TOTAL + V_LEGUMES,
    VDRKGRLEG      = V_DRKGR + V_LEGUMES,
    PFALLPROTLEG   = PF_MPS_TOTAL + PF_EGGS + PF_NUTSDS + PF_SOY + PF_LEGUMES,
    PFSEAPLANTLEG  = PF_SEAFD_HI + PF_SEAFD_LOW + PF_NUTSDS + PF_SOY + PF_LEGUMES
  )

# --------- Sum over days per person (per-person scoring) ----------
BYID <- COHORT %>%
  group_by(SEQN) %>%
  summarise(
    KCAL = sum(KCAL, na.rm = TRUE),
    VTOTALLEG = sum(VTOTALLEG, na.rm = TRUE),
    VDRKGRLEG = sum(VDRKGRLEG, na.rm = TRUE),
    F_TOTAL   = sum(F_TOTAL,   na.rm = TRUE),
    FWHOLEFRT = sum(FWHOLEFRT, na.rm = TRUE),
    G_WHOLE   = sum(G_WHOLE,   na.rm = TRUE),
    D_TOTAL   = sum(D_TOTAL,   na.rm = TRUE),
    PFALLPROTLEG  = sum(PFALLPROTLEG,  na.rm = TRUE),
    PFSEAPLANTLEG = sum(PFSEAPLANTLEG, na.rm = TRUE),
    MONOPOLY  = sum(MONOPOLY,  na.rm = TRUE),
    SFAT      = sum(SFAT,      na.rm = TRUE),
    SODI      = sum(SODI,      na.rm = TRUE),
    G_REFINED = sum(G_REFINED, na.rm = TRUE),
    ADD_SUGARS= sum(ADD_SUGARS,na.rm = TRUE),  # NOTE: still tsp eq; convert below
    .groups = "drop"
  )

# --------- Helper: linear map with truncation ----------
lin_score <- function(x, xmin, xmax, smin, smax) {
  slope <- (smax - smin) / (xmax - xmin)
  val   <- smin + slope * (x - xmin)
  pmax(pmin(val, smax), smin)
}

# --------- HEI-2020 scoring (with corrected added sugars conversion) ----------
HEI2020 <- BYID %>%
  mutate(
    # Densities per 1000 kcal (protect division)
    k1000 = ifelse(KCAL > 0, KCAL/1000, NA_real_),
    
    d_VTOTALLEG = VTOTALLEG / k1000,
    d_VDRKGRLEG = VDRKGRLEG / k1000,
    d_F_TOTAL   = F_TOTAL   / k1000,
    d_FWHOLEFRT = FWHOLEFRT / k1000,
    d_G_WHOLE   = G_WHOLE   / k1000,
    d_D_TOTAL   = D_TOTAL   / k1000,
    d_PFALLPROTLEG  = PFALLPROTLEG  / k1000,
    d_PFSEAPLANTLEG = PFSEAPLANTLEG / k1000,
    d_G_REFINED = G_REFINED / k1000,
    
    # Sodium mg/1000 kcal
    d_SODI_1000 = ifelse(KCAL > 0, (SODI / KCAL) * 1000, NA_real_),
    
    # Ratios / percents
    fatty_ratio = ifelse(SFAT == 0, Inf, MONOPOLY / SFAT),
    
    # >>> CORRECTED ADDED SUGARS: tsp eq × 16 kcal <<<
    ADDSUG_KCAL = ADD_SUGARS * 4.2 * 4,  
    pct_satfat  = ifelse(KCAL > 0, (SFAT * 9)      / KCAL * 100, NA_real_),
    pct_addsug  = ifelse(KCAL > 0, (ADDSUG_KCAL)   / KCAL * 100, NA_real_),
    
    # Adequacy components
    HEI2020_TOTALVEG       = lin_score(d_VTOTALLEG,      0, 1.1, 0,  5),
    HEI2020_GREEN_AND_BEAN = lin_score(d_VDRKGRLEG,      0, 0.2, 0,  5),
    HEI2020_TOTALFRUIT     = lin_score(d_F_TOTAL,        0, 0.8, 0,  5),
    HEI2020_WHOLEFRUIT     = lin_score(d_FWHOLEFRT,      0, 0.4, 0,  5),
    HEI2020_WHOLEGRAIN     = lin_score(d_G_WHOLE,        0, 1.5, 0, 10),
    HEI2020_TOTALDAIRY     = lin_score(d_D_TOTAL,        0, 1.3, 0, 10),
    HEI2020_TOTPROT        = lin_score(d_PFALLPROTLEG,   0, 2.5, 0,  5),
    HEI2020_SEAPLANT_PROT  = lin_score(d_PFSEAPLANTLEG,  0, 0.8, 0,  5),
    HEI2020_FATTYACID      = lin_score(fatty_ratio,    1.2, 2.5, 0, 10),
    
    # Moderation components (note cutpoint order high→low)
    HEI2020_REFINEDGRAIN   = lin_score(d_G_REFINED,    4.3, 1.8, 0, 10),
    HEI2020_SODIUM         = lin_score(d_SODI_1000,    2.0, 1.1, 0, 10),
    HEI2020_SFAT           = lin_score(pct_satfat,       16,   8, 0, 10),
    HEI2020_ADDSUG         = lin_score(pct_addsug,       26, 6.5, 0, 10),
    
    HEI2020_TOTAL_SCORE =
      HEI2020_TOTALVEG + HEI2020_GREEN_AND_BEAN + HEI2020_TOTALFRUIT +
      HEI2020_WHOLEFRUIT + HEI2020_WHOLEGRAIN + HEI2020_TOTALDAIRY +
      HEI2020_TOTPROT + HEI2020_SEAPLANT_PROT + HEI2020_FATTYACID +
      HEI2020_REFINEDGRAIN + HEI2020_SODIUM + HEI2020_SFAT + HEI2020_ADDSUG
  ) %>%
  select(SEQN, KCAL,
         starts_with("HEI2020_"), HEI2020_TOTAL_SCORE)

# Inspect
print(HEI2020)


HEI_total <- HEI2020 %>%
  select(SEQN, HEI2020_TOTAL_SCORE)

print(HEI_total)
