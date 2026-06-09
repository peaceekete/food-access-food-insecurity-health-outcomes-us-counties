-- ============================================================
-- PROJECT  Food Access, Insecurity, Poverty & Health Outcomes Across U.S. Counties
-- SCRIPT   : 01 — Database Setup, Data Import & Master Table
-- Tool     : MySQL 8.0 / MySQL Workbench
-- Author   : Peace Mmesoma Ekete
-- Date     : 2026
-- 
-- DESCRIPTION:
--   Integrates six public health, food access, and
--   socioeconomic datasets into a unified county-level
--   analytical table (master_county) covering 3,129
--   US counties across 51 states/districts.
--
-- DATASETS:
--   FARA   — Food Access Research Atlas (USDA, 2019)
--   FEA    — Food Environment Atlas (USDA)
--   CDC    — CDC PLACES County Data
--   ACS    — American Community Survey (Census Bureau)
--   SAHIE  — Small Area Health Insurance Estimates (Census)
--   CHR    — County Health Rankings
-- ============================================================


-- ============================================================
-- CREATE DATABASE
-- ============================================================

CREATE DATABASE food_desert_analysis;

USE food_desert_analysis;


-- ============================================================
-- ENABLE LOCAL FILE IMPORT
-- ============================================================

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;


-- ============================================================
-- IMPORT CHR DATA
-- Source: County Health Rankings
-- Grain : One row per county
-- ============================================================

CREATE TABLE chr_county (
    County_FIPS             VARCHAR(5),
    State                   VARCHAR(50),
    County                  VARCHAR(100),
    Poor_or_Fair_Health     DOUBLE,
    Food_Insecurity         DOUBLE,
    Physical_Inactivity     DOUBLE,
    Uninsured_Adults        DOUBLE,
    Adult_Smoking           DOUBLE,
    Median_Household_Income DOUBLE,
    Adult_Obesity           DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Documents/New/Clean/CHR_Clean.csv'
INTO TABLE chr_county
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Validate
SELECT COUNT(*) AS chr_rows FROM chr_county;
SELECT County_FIPS, State, Poor_or_Fair_Health, Adult_Obesity
FROM chr_county LIMIT 5;


-- ============================================================
-- IMPORT FEA DATA
-- Source: Food Environment Atlas (USDA)
-- Grain : One row per county
-- ============================================================

CREATE TABLE fea_county (
    County_FIPS               VARCHAR(5),
    Food_Insecurity_18_20     DOUBLE,
    Food_Insecurity_21_23     DOUBLE,
    Very_Low_Insecurity_18_20 DOUBLE,
    Very_Low_Insecurity_21_23 DOUBLE,
    Low_Access_POP_2015       DOUBLE,
    Low_Access_POP_2019       DOUBLE,
    Low_Access_SNAP_2015      DOUBLE,
    Low_Access_SNAP_2019      DOUBLE,
    Grocery_Stores_2016       DOUBLE,
    Grocery_Stores_2020       DOUBLE,
    Store_Growth_Rate_16_20   DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Documents/New/Clean/FEA_Clean.csv'
INTO TABLE fea_county
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Validate
SELECT COUNT(*) AS fea_rows FROM fea_county;
SELECT County_FIPS, Food_Insecurity_18_20, Grocery_Stores_2020
FROM fea_county LIMIT 5;


-- ============================================================
-- IMPORT ACS DATA
-- Source: American Community Survey (Census Bureau)
-- Grain : One row per county
-- ============================================================

CREATE TABLE acs_county (
    County_FIPS       VARCHAR(5),
    Median_HH_Income  DOUBLE,
    Unemployment_Rate DOUBLE,
    PCT_Poverty       DOUBLE,
    Total_Pop         DOUBLE,
    PCT_65_Year_Plus  DOUBLE,
    PCT_Hispanic      DOUBLE,
    PCT_Black         DOUBLE,
    PCT_White         DOUBLE,
    PCT_Poverty_1701  DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Documents/New/Clean/Merged_ASC_Clean.csv'
INTO TABLE acs_county
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Validate
SELECT COUNT(*) AS acs_rows FROM acs_county;
SELECT County_FIPS, Median_HH_Income, PCT_Poverty, Total_Pop
FROM acs_county LIMIT 5;


-- ============================================================
-- IMPORT CDC PLACES DATA
-- Source: CDC PLACES County Data
-- Grain : One row per county
-- ============================================================

CREATE TABLE cdc_places_county (
    County_FIPS                 VARCHAR(5),
    State                       VARCHAR(50),
    Coronary_Heart_Disease_Prev DOUBLE,
    Smoking_Prev                DOUBLE,
    Diabetes_Prev               DOUBLE,
    Physical_Inactivity_Prev    DOUBLE,
    Obesity_Prev                DOUBLE,
    Uninsured_Prev              DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Documents/New/Clean/CDC_Places_Cleaned.csv'
INTO TABLE cdc_places_county
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Validate
SELECT COUNT(*) AS cdc_rows FROM cdc_places_county;
SELECT County_FIPS, State, Diabetes_Prev, Obesity_Prev,
       Coronary_Heart_Disease_Prev
FROM cdc_places_county LIMIT 5;


-- ============================================================
-- IMPORT SAHIE DATA 
-- Source: Small Area Health Insurance Estimates (Census Bureau)
-- Grain : One row per county
-- ============================================================

CREATE TABLE sahie_county (
    Age_Category              VARCHAR(10),
    Race_Category             VARCHAR(10),
    Sex_Category              VARCHAR(10),
    Income_Priority_Category  VARCHAR(10),
    State_FIPS                VARCHAR(10),
    PCT_Uninsured             VARCHAR(20),
    PCT_Uninsured_MOE         VARCHAR(20),
    State                     VARCHAR(50),
    County_FIPS               VARCHAR(10)
);

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Documents/New/Clean/SAHIE_Clean.csv'
INTO TABLE sahie_county
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Validate
SELECT COUNT(*) AS sahie_rows FROM sahie_county;
SELECT County_FIPS, State, PCT_Uninsured
FROM sahie_county LIMIT 5;


-- ============================================================
-- IMPORT FARA DATA 
-- Source: Food Access Research Atlas (USDA, 2019)
-- Grain : One row per census tract (72,530 tracts)
--
--  Original FIPS codes were corrupted in source file.
-- Re-extracted using =TEXT(LEFT(CensusTract,5),"00000")
-- in Excel and saved as FARA_Cleaned_V2.csv.
-- Tract_ID column removed — not needed for analysis.
-- ============================================================

CREATE TABLE fara_tract (
    County_FIPS                     VARCHAR(5),
    State                           VARCHAR(50),
    County                          VARCHAR(100),
    Urban                           INT,
    Total_Pop                       INT,
    PCT_Low_Access_1Mile            DOUBLE,
    PCT_Low_Income_Low_Access_1Mile DOUBLE,
    PCT_Seniors_Low_Access_1Mile    DOUBLE
);

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Documents/New/Clean/FARA_Cleaned_V2.csv'
INTO TABLE fara_tract
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Validate
SELECT COUNT(*) AS fara_tract_rows FROM fara_tract;
SELECT County_FIPS, State, County, Total_Pop
FROM fara_tract LIMIT 10;


-- ============================================================
-- AGGREGATE FARA FROM TRACT TO COUNTY LEVEL
-- Raw FARA data is at census tract grain (72,530 rows).
-- Aggregated to county level using population-weighted averages
-- to ensure larger tracts don't get equal weight to smaller ones.
-- Result: fara_county with 3,142 rows, one row per county.
-- ============================================================

CREATE TABLE fara_county AS
SELECT
    County_FIPS,
    MAX(State)   AS State,
    MAX(County)  AS County,
    MAX(Urban)   AS Urban,
    SUM(Total_Pop) AS Total_Pop,
    ROUND(SUM(PCT_Low_Access_1Mile * Total_Pop)
        / NULLIF(SUM(Total_Pop), 0), 4)            AS PCT_Low_Access_1Mile,
    ROUND(SUM(PCT_Low_Income_Low_Access_1Mile * Total_Pop)
        / NULLIF(SUM(Total_Pop), 0), 4)            AS PCT_Low_Income_Low_Access_1Mile,
    ROUND(SUM(PCT_Seniors_Low_Access_1Mile * Total_Pop)
        / NULLIF(SUM(Total_Pop), 0), 4)            AS PCT_Seniors_Low_Access_1Mile
FROM fara_tract
GROUP BY County_FIPS;

-- Validate
SELECT COUNT(*) AS fara_county_rows FROM fara_county;
SELECT County_FIPS, State, County, PCT_Low_Access_1Mile
FROM fara_county
WHERE County_FIPS IN ('01001', '06037', '48201');


-- ============================================================
-- BUILD MASTER COUNTY TABLE
-- Joins all six datasets on County_FIPS.
-- CDC PLACES used as the base table (3,145 counties)
-- because it contains the outcome variables.
-- All other datasets joined using LEFT JOIN to preserve
-- all CDC counties even where source data is missing.
-- ============================================================

CREATE TABLE master_county AS
SELECT
    c.County_FIPS,
    c.State,
    f.County,
    f.PCT_Low_Access_1Mile,
    f.PCT_Low_Income_Low_Access_1Mile,
    f.PCT_Seniors_Low_Access_1Mile,
    f.Urban,
    fe.Food_Insecurity_18_20,
    fe.Food_Insecurity_21_23,
    fe.Grocery_Stores_2020,
    fe.Store_Growth_Rate_16_20,
    fe.Low_Access_POP_2019,
    c.Diabetes_Prev,
    c.Obesity_Prev,
    c.Coronary_Heart_Disease_Prev,
    c.Physical_Inactivity_Prev,
    c.Smoking_Prev,
    a.Total_Pop,
    a.Median_HH_Income,
    a.Unemployment_Rate,
    a.PCT_Poverty,
    a.PCT_65_Year_Plus,
    a.PCT_Hispanic,
    a.PCT_Black,
    a.PCT_White,
    CAST(s.PCT_Uninsured AS DECIMAL(10,4)) AS PCT_Uninsured,
    ch.Poor_or_Fair_Health,
    ch.Food_Insecurity,
    ch.Physical_Inactivity,
    ch.Adult_Obesity,
    ch.Adult_Smoking,
    ch.Median_Household_Income
FROM cdc_places_county c
LEFT JOIN fara_county       f  ON c.County_FIPS = f.County_FIPS
LEFT JOIN fea_county        fe ON c.County_FIPS = fe.County_FIPS
LEFT JOIN acs_county        a  ON c.County_FIPS = a.County_FIPS
LEFT JOIN sahie_county      s  ON c.County_FIPS = s.County_FIPS
LEFT JOIN chr_county        ch ON c.County_FIPS = ch.County_FIPS;

-- Validate
SELECT COUNT(*) AS master_rows FROM master_county;

SELECT County_FIPS, State, County,
       Diabetes_Prev, Obesity_Prev,
       Median_HH_Income, PCT_Low_Access_1Mile,
       PCT_Black, PCT_Hispanic
FROM master_county
WHERE County_FIPS IN ('01001', '06037', '48201');

-- Confirm all key columns populated
SELECT
    COUNT(*)               AS total_rows,
    COUNT(Total_Pop)       AS has_population,
    COUNT(PCT_Hispanic)    AS has_hispanic,
    COUNT(PCT_Black)       AS has_black,
    COUNT(PCT_White)       AS has_white,
    COUNT(PCT_Uninsured)   AS has_uninsured,
    COUNT(PCT_Low_Access_1Mile) AS has_fara,
    COUNT(Diabetes_Prev)   AS has_diabetes,
    COUNT(Median_HH_Income) AS has_income
FROM master_county;


-- ============================================================
-- EXPORT MASTER COUNTY TO CSV
-- ============================================================

SELECT * FROM master_county
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/master_county_final.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

