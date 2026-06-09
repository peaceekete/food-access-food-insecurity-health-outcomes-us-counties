-- ============================================================
-- PROJECT  Food Access, Insecurity, Poverty & Health Outcomes Across U.S. Counties
-- SCRIPT   :EDA
-- Tool     : MySQL 8.0 / MySQL Workbench
-- Author   : Peace Mmesoma Ekete
-- Date     : 2026
-- =============================================================

USE food_desert_analysis;

-- ============================================================
-- SECTION 1: DATA QUALITY CHECKS
-- ============================================================

-- Starting with a basic count -- expected 3,145 rows
SELECT COUNT(*) AS Total_Rows
FROM master_county;

-- Checking nulls across all the key columns before touching anything
SELECT
    SUM(CASE WHEN County_FIPS             IS NULL THEN 1 ELSE 0 END) AS Null_FIPS,
    SUM(CASE WHEN Diabetes_Prev           IS NULL THEN 1 ELSE 0 END) AS Null_Diabetes,
    SUM(CASE WHEN Obesity_Prev            IS NULL THEN 1 ELSE 0 END) AS Null_Obesity,
    SUM(CASE WHEN Coronary_Heart_Disease_Prev IS NULL THEN 1 ELSE 0 END) AS Null_HeartDisease,
    SUM(CASE WHEN PCT_Low_Access_1Mile    IS NULL THEN 1 ELSE 0 END) AS Null_LowAccess,
    SUM(CASE WHEN Median_HH_Income        IS NULL THEN 1 ELSE 0 END) AS Null_Income,
    SUM(CASE WHEN PCT_Poverty             IS NULL THEN 1 ELSE 0 END) AS Null_Poverty,
    SUM(CASE WHEN Food_Insecurity_18_20   IS NULL THEN 1 ELSE 0 END) AS Null_FoodInsecurity,
    SUM(CASE WHEN PCT_Uninsured           IS NULL THEN 1 ELSE 0 END) AS Null_Uninsured
FROM master_county;


-- ============================================================
-- SECTION 2: DROPPING UNRESOLVABLE ROWS
-- ============================================================

-- '00059' is a national summary row, not an actual county
-- '09190' is a CT restructured county that doesn't map to FARA geography
DELETE FROM master_county
WHERE County_FIPS = '00059'
   OR County_FIPS = '09190';

-- The remaining PCT_Low_Access_1Mile nulls are all AK new boroughs,
-- CT redistricted counties, and VA independent cities -- FARA 2019
-- geography mismatch, can't be fixed so dropping them
DELETE FROM master_county
WHERE PCT_Low_Access_1Mile IS NULL;

-- Should return 3,131 after the above drops
SELECT COUNT(*) AS Remaining_Counties
FROM master_county;

-- Checking which counties still have scattered nulls in other columns
SELECT County_FIPS, State, County,
       Median_HH_Income, PCT_Poverty,
       Food_Insecurity_18_20, PCT_Uninsured
FROM master_county
WHERE Median_HH_Income    IS NULL
   OR PCT_Poverty         IS NULL
   OR Food_Insecurity_18_20 IS NULL
   OR PCT_Uninsured       IS NULL;

-- Kalawao County (FIPS 15005) -- population ~85, SAHIE suppresses
-- estimates for counties this small, not imputable so dropping it
DELETE FROM master_county
WHERE County_FIPS = '15005';

-- Confirm nulls are gone
SELECT
    SUM(CASE WHEN Median_HH_Income      IS NULL THEN 1 ELSE 0 END) AS Null_Income,
    SUM(CASE WHEN PCT_Poverty           IS NULL THEN 1 ELSE 0 END) AS Null_Poverty,
    SUM(CASE WHEN Food_Insecurity_18_20 IS NULL THEN 1 ELSE 0 END) AS Null_FoodInsecurity,
    SUM(CASE WHEN PCT_Uninsured         IS NULL THEN 1 ELSE 0 END) AS Null_Uninsured
FROM master_county;

SELECT COUNT(*) AS Final_County_Count FROM master_county;


-- ============================================================
-- SECTION 3: DESCRIPTIVE STATISTICS
-- ============================================================

SELECT
    ROUND(AVG(Diabetes_Prev), 2)                AS Avg_Diabetes,
    ROUND(STDDEV(Diabetes_Prev), 2)             AS Std_Diabetes,
    MIN(Diabetes_Prev)                          AS Min_Diabetes,
    MAX(Diabetes_Prev)                          AS Max_Diabetes,

    ROUND(AVG(Obesity_Prev), 2)                 AS Avg_Obesity,
    ROUND(STDDEV(Obesity_Prev), 2)              AS Std_Obesity,
    MIN(Obesity_Prev)                           AS Min_Obesity,
    MAX(Obesity_Prev)                           AS Max_Obesity,

    ROUND(AVG(Coronary_Heart_Disease_Prev), 2)  AS Avg_HeartDisease,
    ROUND(STDDEV(Coronary_Heart_Disease_Prev), 2) AS Std_HeartDisease,
    MIN(Coronary_Heart_Disease_Prev)            AS Min_HeartDisease,
    MAX(Coronary_Heart_Disease_Prev)            AS Max_HeartDisease,

    ROUND(AVG(PCT_Low_Access_1Mile), 2)         AS Avg_LowAccess,
    ROUND(STDDEV(PCT_Low_Access_1Mile), 2)      AS Std_LowAccess,
    MIN(PCT_Low_Access_1Mile)                   AS Min_LowAccess,
    MAX(PCT_Low_Access_1Mile)                   AS Max_LowAccess,

    ROUND(AVG(Median_HH_Income), 2)             AS Avg_Income,
    ROUND(STDDEV(Median_HH_Income), 2)          AS Std_Income,
    MIN(Median_HH_Income)                       AS Min_Income,
    MAX(Median_HH_Income)                       AS Max_Income,

    ROUND(AVG(PCT_Poverty), 2)                  AS Avg_Poverty,
    ROUND(STDDEV(PCT_Poverty), 2)               AS Std_Poverty,
    MIN(PCT_Poverty)                            AS Min_Poverty,
    MAX(PCT_Poverty)                            AS Max_Poverty,

    ROUND(AVG(PCT_Uninsured), 2)                AS Avg_Uninsured,
    ROUND(STDDEV(PCT_Uninsured), 2)             AS Std_Uninsured,
    MIN(PCT_Uninsured)                          AS Min_Uninsured,
    MAX(PCT_Uninsured)                          AS Max_Uninsured,

    ROUND(AVG(Unemployment_Rate), 2)            AS Avg_Unemployment,
    ROUND(STDDEV(Unemployment_Rate), 2)         AS Std_Unemployment,
    MIN(Unemployment_Rate)                      AS Min_Unemployment,
    MAX(Unemployment_Rate)                      AS Max_Unemployment
FROM master_county;

-- Quick spot check on the raw values before any conversions
SELECT 
    County_FIPS, State, County,
    Diabetes_Prev,
    Obesity_Prev,
    PCT_Low_Access_1Mile,
    PCT_Poverty
FROM master_county
LIMIT 10;


-- ============================================================
-- SECTION 4: CONVERTING PROPORTIONS TO PERCENTAGES
-- ============================================================

-- Several columns came in as proportions (e.g. 0.12 instead of 12%)
-- PCT_Low_Access_1Mile is already on a 0-100 scale so leaving that one
UPDATE master_county SET
    Diabetes_Prev                   = ROUND(Diabetes_Prev * 100, 2),
    Obesity_Prev                    = ROUND(Obesity_Prev * 100, 2),
    Coronary_Heart_Disease_Prev     = ROUND(Coronary_Heart_Disease_Prev * 100, 2),
    PCT_Low_Income_Low_Access_1Mile = ROUND(PCT_Low_Income_Low_Access_1Mile * 100, 2),
    PCT_Seniors_Low_Access_1Mile    = ROUND(PCT_Seniors_Low_Access_1Mile * 100, 2),
    PCT_Poverty                     = ROUND(PCT_Poverty * 100, 2),
    PCT_Uninsured                   = ROUND(PCT_Uninsured * 100, 2),
    Unemployment_Rate               = ROUND(Unemployment_Rate * 100, 2),
    PCT_65_Year_Plus                = ROUND(PCT_65_Year_Plus * 100, 2),
    PCT_Hispanic                    = ROUND(PCT_Hispanic * 100, 2),
    PCT_Black                       = ROUND(PCT_Black * 100, 2),
    PCT_White                       = ROUND(PCT_White * 100, 2),
    Physical_Inactivity_Prev        = ROUND(Physical_Inactivity_Prev * 100, 2),
    Smoking_Prev                    = ROUND(Smoking_Prev * 100, 2),
    Food_Insecurity_18_20           = ROUND(Food_Insecurity_18_20 * 100, 2),
    Food_Insecurity_21_23           = ROUND(Food_Insecurity_21_23 * 100, 2);

-- Verify the conversion looks right
SELECT 
    County_FIPS, State, County,
    Diabetes_Prev,
    Obesity_Prev,
    PCT_Low_Access_1Mile,
    PCT_Poverty
FROM master_county
LIMIT 10;


-- ============================================================
-- SECTION 5: INVESTIGATING SUSPICIOUS VALUES
-- ============================================================

-- Flagging anything that looks impossible before moving on
SELECT County_FIPS, State, County, 
       Median_HH_Income, PCT_Poverty, Unemployment_Rate
FROM master_county
WHERE Median_HH_Income < 10000
   OR PCT_Poverty > 45
   OR Unemployment_Rate > 25;

-- De Baca County has an income value that can't be right -- ACS data error
DELETE FROM master_county
WHERE County_FIPS = '35011';

-- Final clean count
SELECT COUNT(*) AS Final_Count FROM master_county;

-- Confirm no more impossible values
SELECT 
    MIN(Median_HH_Income)  AS Min_Income,
    MIN(PCT_Poverty)       AS Min_Poverty,
    MIN(Unemployment_Rate) AS Min_Unemployment
FROM master_county;


-- ============================================================
-- SECTION 6: URBAN VS RURAL DISTRIBUTION
-- ============================================================

-- Urban = 1, Rural = 0
SELECT 
    Urban,
    COUNT(*)                              AS County_Count,
    ROUND(AVG(Diabetes_Prev), 2)          AS Avg_Diabetes,
    ROUND(AVG(Obesity_Prev), 2)           AS Avg_Obesity,
    ROUND(AVG(Coronary_Heart_Disease_Prev), 2) AS Avg_HeartDisease,
    ROUND(AVG(PCT_Low_Access_1Mile), 2)   AS Avg_LowAccess,
    ROUND(AVG(Median_HH_Income), 2)       AS Avg_Income,
    ROUND(AVG(PCT_Poverty), 2)            AS Avg_Poverty
FROM master_county
GROUP BY Urban
ORDER BY Urban;

-- Confirming 50 states are present (DC excluded -- not in county-level FARA data)
SELECT COUNT(DISTINCT State) AS Distinct_States
FROM master_county;


-- ============================================================
-- SECTION 7: TOP 10 COUNTIES BY DISEASE OUTCOME
-- ============================================================

-- Highest diabetes counties
SELECT 
    County_FIPS, State, County,
    Diabetes_Prev,
    Obesity_Prev,
    PCT_Low_Access_1Mile,
    Median_HH_Income,
    PCT_Poverty,
    Urban
FROM master_county
ORDER BY Diabetes_Prev DESC
LIMIT 10;

-- Highest obesity counties
SELECT 
    County_FIPS, State, County,
    Obesity_Prev,
    Diabetes_Prev,
    PCT_Low_Access_1Mile,
    Median_HH_Income,
    PCT_Poverty,
    Urban
FROM master_county
ORDER BY Obesity_Prev DESC
LIMIT 10;

-- Highest heart disease counties
SELECT 
    County_FIPS, State, County,
    Coronary_Heart_Disease_Prev,
    Obesity_Prev,
    PCT_Low_Access_1Mile,
    Median_HH_Income,
    PCT_Poverty,
    Urban
FROM master_county
ORDER BY Coronary_Heart_Disease_Prev DESC
LIMIT 10;


-- ============================================================
-- SECTION 8: CORRELATION PROXIES
-- ============================================================

-- Pearson correlation between food access and outcomes,
-- plus poverty and income vs diabetes as a comparison baseline
SELECT
    ROUND(
        (AVG(PCT_Low_Access_1Mile * Diabetes_Prev) - AVG(PCT_Low_Access_1Mile) * AVG(Diabetes_Prev)) /
        (STDDEV(PCT_Low_Access_1Mile) * STDDEV(Diabetes_Prev)), 4)
        AS Corr_LowAccess_Diabetes,

    ROUND(
        (AVG(PCT_Low_Access_1Mile * Obesity_Prev) - AVG(PCT_Low_Access_1Mile) * AVG(Obesity_Prev)) /
        (STDDEV(PCT_Low_Access_1Mile) * STDDEV(Obesity_Prev)), 4)
        AS Corr_LowAccess_Obesity,

    ROUND(
        (AVG(PCT_Low_Access_1Mile * Coronary_Heart_Disease_Prev) - AVG(PCT_Low_Access_1Mile) * AVG(Coronary_Heart_Disease_Prev)) /
        (STDDEV(PCT_Low_Access_1Mile) * STDDEV(Coronary_Heart_Disease_Prev)), 4)
        AS Corr_LowAccess_HeartDisease,

    ROUND(
        (AVG(PCT_Poverty * Diabetes_Prev) - AVG(PCT_Poverty) * AVG(Diabetes_Prev)) /
        (STDDEV(PCT_Poverty) * STDDEV(Diabetes_Prev)), 4)
        AS Corr_Poverty_Diabetes,

    ROUND(
        (AVG(Median_HH_Income * Diabetes_Prev) - AVG(Median_HH_Income) * AVG(Diabetes_Prev)) /
        (STDDEV(Median_HH_Income) * STDDEV(Diabetes_Prev)), 4)
        AS Corr_Income_Diabetes

FROM master_county;


-- ============================================================
-- SECTION 9: STATE LEVEL SUMMARY
-- ============================================================

SELECT 
    State,
    COUNT(*)                                      AS County_Count,
    ROUND(AVG(Diabetes_Prev), 2)                  AS Avg_Diabetes,
    ROUND(AVG(Obesity_Prev), 2)                   AS Avg_Obesity,
    ROUND(AVG(Coronary_Heart_Disease_Prev), 2)    AS Avg_HeartDisease,
    ROUND(AVG(PCT_Low_Access_1Mile), 2)           AS Avg_LowAccess,
    ROUND(AVG(Median_HH_Income), 2)               AS Avg_Income,
    ROUND(AVG(PCT_Poverty), 2)                    AS Avg_Poverty
FROM master_county
GROUP BY State
ORDER BY Avg_Diabetes DESC;


-- ============================================================
-- SECTION 10: LOW ACCESS QUARTILE ANALYSIS
-- ============================================================

-- Breaking food access into quartiles to see how outcomes shift
-- as access gets worse
SELECT
    LowAccess_Quartile,
    COUNT(*)                                        AS County_Count,
    ROUND(MIN(PCT_Low_Access_1Mile), 1)             AS Min_LowAccess_PCT,
    ROUND(MAX(PCT_Low_Access_1Mile), 1)             AS Max_LowAccess_PCT,
    ROUND(AVG(Diabetes_Prev), 2)                    AS Avg_Diabetes,
    ROUND(AVG(Obesity_Prev), 2)                     AS Avg_Obesity,
    ROUND(AVG(Coronary_Heart_Disease_Prev), 2)      AS Avg_HeartDisease,
    ROUND(AVG(Median_HH_Income), 0)                 AS Avg_Income
FROM (
    SELECT *,
        NTILE(4) OVER (ORDER BY PCT_Low_Access_1Mile) AS LowAccess_Quartile
    FROM master_county
) AS sub
GROUP BY LowAccess_Quartile
ORDER BY LowAccess_Quartile;


-- ============================================================
-- SECTION 11: POVERTY QUINTILES VS HEALTH OUTCOMES
-- ============================================================

SELECT
    Poverty_Quintile,
    COUNT(*)                                    AS County_Count,
    ROUND(AVG(PCT_Poverty), 2)                 AS Avg_Poverty_Rate,
    ROUND(AVG(Diabetes_Prev), 2)               AS Avg_Diabetes,
    ROUND(AVG(Obesity_Prev), 2)                AS Avg_Obesity,
    ROUND(AVG(Coronary_Heart_Disease_Prev), 2) AS Avg_HeartDisease,
    ROUND(AVG(PCT_Low_Access_1Mile), 2)        AS Avg_LowAccess
FROM (
    SELECT *,
        NTILE(5) OVER (ORDER BY PCT_Poverty) AS Poverty_Quintile
    FROM master_county
) AS sub
GROUP BY Poverty_Quintile
ORDER BY Poverty_Quintile;


-- ============================================================
-- SECTION 12: CROSS-SOURCE CONSISTENCY CHECKS
-- ============================================================

-- CDC and County Health Rankings both have obesity and inactivity --
-- checking how far apart they are
SELECT
    ROUND(AVG(Obesity_Prev), 2)                         AS CDC_Avg_Obesity,
    ROUND(AVG(Adult_Obesity), 2)                        AS CHR_Avg_Obesity,
    ROUND(AVG(Obesity_Prev - Adult_Obesity), 2)         AS Avg_Difference_Obesity,

    ROUND(AVG(Physical_Inactivity_Prev), 2)             AS CDC_Avg_Inactivity,
    ROUND(AVG(Physical_Inactivity), 2)                  AS CHR_Avg_Inactivity,
    ROUND(AVG(Physical_Inactivity_Prev - Physical_Inactivity), 2) AS Avg_Difference_Inactivity,

    ROUND(AVG(Median_HH_Income), 0)                     AS ACS_Avg_Income,
    ROUND(AVG(Median_Household_Income), 0)              AS CHR_Avg_Income,
    ROUND(AVG(Median_HH_Income - Median_Household_Income), 0) AS Avg_Difference_Income
FROM master_county;

-- CHR obesity and inactivity columns also came in as proportions -- fixing those
UPDATE master_county SET
    Adult_Obesity        = ROUND(Adult_Obesity * 100, 2),
    Physical_Inactivity  = ROUND(Physical_Inactivity * 100, 2);

-- Verify
SELECT 
    ROUND(AVG(Adult_Obesity), 2)       AS CHR_Avg_Obesity_Fixed,
    ROUND(AVG(Physical_Inactivity), 2) AS CHR_Avg_Inactivity_Fixed
FROM master_county;


-- ============================================================
-- SECTION 13: FIXING PCT_65_Year_Plus
-- ============================================================

-- Noticed PCT_65_Year_Plus and Total_Pop had been swapped during the join --
-- the "percentage" values were in the millions which gave it away.
-- Recalculating directly from the ACS source table to fix it properly

SET SQL_SAFE_UPDATES = 0;

UPDATE master_county m
JOIN acs_county a ON m.County_FIPS = a.County_FIPS
SET m.PCT_65_Year_Plus = ROUND((a.PCT_65_Year_Plus / a.Total_Pop) * 100, 2);

SET SQL_SAFE_UPDATES = 1;

-- Verify the fix
SELECT 
    County_FIPS, State, County,
    PCT_65_Year_Plus,
    Total_Pop
FROM master_county
LIMIT 5;


-- ============================================================
-- SECTION 14: EXPORT CLEAN DATA
-- ============================================================

SELECT 
    'County_FIPS', 'State', 'County',
    'PCT_Low_Access_1Mile', 'PCT_Low_Income_Low_Access_1Mile',
    'PCT_Seniors_Low_Access_1Mile', 'Urban',
    'Food_Insecurity_18_20', 'Food_Insecurity_21_23',
    'Grocery_Stores_2020', 'Store_Growth_Rate_16_20',
    'Low_Access_POP_2019', 'Diabetes_Prev', 'Obesity_Prev',
    'Coronary_Heart_Disease_Prev', 'Physical_Inactivity_Prev',
    'Smoking_Prev', 'Total_Pop', 'Median_HH_Income',
    'Unemployment_Rate', 'PCT_Poverty', 'PCT_65_Year_Plus',
    'PCT_Hispanic', 'PCT_Black', 'PCT_White', 'PCT_Uninsured',
    'Poor_or_Fair_Health', 'Food_Insecurity', 'Physical_Inactivity',
    'Adult_Obesity', 'Adult_Smoking', 'Median_Household_Income'

UNION ALL

SELECT * FROM master_county

INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/master_county_final.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
s