# DAX Measures — Food Access, Insecurity, Poverty & Health Outcomes Across U.S. Counties

All measures are built on `master_county_final`, a cleaned county-level dataset covering 3,129 U.S. counties.
Population-weighted averages are used throughout to prevent small rural counties from distorting national and state-level figures.

---

## Page 1 — National Health Risk & Geographic Prevalence

### Counties Analyzed
Simple distinct count of counties in the dataset.
```dax
Counties Analyzed = DISTINCTCOUNT(master_county_final[County_FIPS_Fixed])
```

---

### Selected Disease Prevalence
Population-weighted average prevalence for whichever disease the user selects on the slicer. Defaults to diabetes if nothing is selected.
```dax
Selected Disease Prevalence = 
VAR SelectedOutcome = SELECTEDVALUE('Slicer_Table'[Disease])
RETURN
    DIVIDE(
        SUMX(
            'master_county_final', 
            SWITCH(
                SelectedOutcome,
                "Diabetes", 'master_county_final'[Diabetes_Prev],
                "Obesity", 'master_county_final'[Obesity_Prev],
                "Heart_Disease", 'master_county_final'[Coronary_Heart_Disease_Prev],
                'master_county_final'[Diabetes_Prev]
            ) * 'master_county_final'[Total_Pop]
        ),
        SUM('master_county_final'[Total_Pop])
    ) / 100
```

---

### Rural–Urban Relative Health Gap
Calculates the percentage gap between rural and urban population-weighted disease prevalence for the selected disease. Used as the 21% KPI card.
```dax
Rural–Urban Relative Health Gap = 
VAR SelectedOutcome = SELECTEDVALUE(Slicer_Table[Disease])

VAR RuralAvg =
    DIVIDE(
        SUMX(
            FILTER(master_county_final, master_county_final[Urban] = 0),
            SWITCH(SelectedOutcome,
                "Diabetes", master_county_final[Diabetes_Prev],
                "Heart_Disease", master_county_final[Coronary_Heart_Disease_Prev],
                "Obesity", master_county_final[Obesity_Prev]
            ) * master_county_final[Total_Pop]
        ),
        SUMX(
            FILTER(master_county_final, master_county_final[Urban] = 0),
            master_county_final[Total_Pop]
        )
    )

VAR UrbanAvg =
    DIVIDE(
        SUMX(
            FILTER(master_county_final, master_county_final[Urban] = 1),
            SWITCH(SelectedOutcome,
                "Diabetes", master_county_final[Diabetes_Prev],
                "Heart_Disease", master_county_final[Coronary_Heart_Disease_Prev],
                "Obesity", master_county_final[Obesity_Prev]
            ) * master_county_final[Total_Pop]
        ),
        SUMX(
            FILTER(master_county_final, master_county_final[Urban] = 1),
            master_county_final[Total_Pop]
        )
    )

RETURN
    DIVIDE(RuralAvg - UrbanAvg, UrbanAvg)
```

---

### Highest Prevalence State
Returns the state with the highest population-weighted disease prevalence for the selected disease.
```dax
Highest Prevalence State = 
VAR SelectedOutcome = SELECTEDVALUE('Slicer_Table'[Disease])
RETURN
    SWITCH(
        SelectedOutcome,
        "Diabetes", 
            MAXX(
                TOPN(1, ALL('State_Lookup'[State_Full]), [National Diabetes Rate], DESC), 
                'State_Lookup'[State_Full]
            ),
        "Heart_Disease", 
            MAXX(
                TOPN(1, ALL('State_Lookup'[State_Full]), [National Heart Disease Rate], DESC), 
                'State_Lookup'[State_Full]
            ),
        "Obesity", 
            MAXX(
                TOPN(1, ALL('State_Lookup'[State_Full]), [National Obesity Rate], DESC), 
                'State_Lookup'[State_Full]
            ),
        MAXX(
            TOPN(1, ALL('State_Lookup'[State_Full]), [National Diabetes Rate], DESC), 
            'State_Lookup'[State_Full]
        )
    )
```

---

### Most Affected County
Returns the county with the highest disease prevalence for the selected disease.
```dax
Most Affected County = 
VAR SelectedOutcome = SELECTEDVALUE(Slicer_Table[Disease])
VAR TopCounty = 
    SWITCH(
        SelectedOutcome,
        "Diabetes", 
            CALCULATE(
                FIRSTNONBLANK(master_county_final[County], 1),
                TOPN(1, ALL(master_county_final), master_county_final[Diabetes_Prev], DESC)
            ),
        "Heart_Disease", 
            CALCULATE(
                FIRSTNONBLANK(master_county_final[County], 1),
                TOPN(1, ALL(master_county_final), master_county_final[Coronary_Heart_Disease_Prev], DESC)
            ),
        "Obesity", 
            CALCULATE(
                FIRSTNONBLANK(master_county_final[County], 1),
                TOPN(1, ALL(master_county_final), master_county_final[Obesity_Prev], DESC)
            )
    )
RETURN TopCounty
```

---

### State Deviation
Calculates how far each state's disease prevalence sits above or below the national average for the selected disease.
```dax
State Deviation = 
VAR NationalAvg =
    CALCULATE(
        [Selected Disease Prevalence],
        ALL(master_county_final)
    )
RETURN
    [Selected Disease Prevalence] - NationalAvg
```

---

### Urban Rural Health Risk Disparity
Powers the urban vs. rural comparison bar chart. Returns the population-weighted average prevalence filtered by urban or rural designation.
```dax
UrbanRural Health Risk Disparity = 
VAR SelectedMetric = SELECTEDVALUE(Urban_Rural_Comparison[Metric])
VAR SelectedEnvironment = SELECTEDVALUE(Urban_Rural_Comparison[Urban_Rural])
RETURN
CALCULATE(
    DIVIDE(
        SUMX(
            'master_county_final',
            SWITCH(
                SelectedMetric,
                "Diabetes", 'master_county_final'[Diabetes_Prev],
                "Obesity", 'master_county_final'[Obesity_Prev],
                "Heart Disease", 'master_county_final'[Coronary_Heart_Disease_Prev]
            ) * 'master_county_final'[Total_Pop]
        ),
        SUM('master_county_final'[Total_Pop])
    ) / 100,
    'master_county_final'[Urban_Rural] = SelectedEnvironment
)
```

---

## Page 2 — Socioeconomic Drivers of Food Insecurity & Chronic Disease

### % High Risk Counties
Percentage of counties classified as above the national average on the selected disease outcome.
```dax
% High Risk Counties = 
DIVIDE(
    [Counties Above National Avg],
    COUNTROWS(master_county_final)
)
```

---

### Food Insecurity–Health Correlation
Computes the Pearson correlation coefficient between food insecurity rate and the selected disease prevalence across all counties. Built manually in DAX without using a built-in correlation function.
```dax
Food Insecurity–Health Correlation = 
VAR MeanX =
    AVERAGEX(
        master_county_final,
        master_county_final[Food_Insecurity_21_23]
    )
VAR MeanY =
    AVERAGEX(
        master_county_final,
        [Selected Disease Prevalence]
    )
VAR Numerator =
    SUMX(
        master_county_final,
        (master_county_final[Food_Insecurity_21_23] - MeanX) *
        ([Selected Disease Prevalence] - MeanY)
    )
VAR DenX =
    SQRT(
        SUMX(
            master_county_final,
            POWER(master_county_final[Food_Insecurity_21_23] - MeanX, 2)
        )
    )
VAR DenY =
    SQRT(
        SUMX(
            master_county_final,
            POWER([Selected Disease Prevalence] - MeanY, 2)
        )
    )
RETURN
DIVIDE(Numerator, DenX * DenY)
```

---

### National Food Insecurity Rate
Population-weighted national food insecurity rate using post-COVID data (2021–2023).
```dax
National Food Insecurity Rate = 
DIVIDE(
    SUMX(
        master_county_final,
        master_county_final[Food_Insecurity_21_23] * master_county_final[Total_Pop]
    ),
    SUM(master_county_final[Total_Pop])
)/100
```

---

### % of Counties with High Food Insecurity-High Disease
Identifies the share of counties simultaneously above the median on both food insecurity and disease prevalence — the compounding risk quadrant.
```dax
% of Counties with High Food Insecurity-High Disease = 
VAR MedianFI =
    CALCULATE(
        MEDIAN(master_county_final[Food_Insecurity_21_23]),
        ALL(master_county_final)
    )
VAR SelectedOutcome = SELECTEDVALUE(Slicer_Table[Disease])
VAR MedianOutcome =
    SWITCH(
        SelectedOutcome,
        "Diabetes", CALCULATE(MEDIAN(master_county_final[Diabetes_Prev]), ALL(master_county_final)),
        "Obesity", CALCULATE(MEDIAN(master_county_final[Obesity_Prev]), ALL(master_county_final)),
        "Heart_Disease", CALCULATE(MEDIAN(master_county_final[Coronary_Heart_Disease_Prev]), ALL(master_county_final))
    )
VAR CountBoth =
    CALCULATE(
        COUNTROWS(master_county_final),
        FILTER(
            master_county_final,
            master_county_final[Food_Insecurity_21_23] > MedianFI
                &&
            SWITCH(
                SelectedOutcome,
                "Diabetes", master_county_final[Diabetes_Prev],
                "Obesity", master_county_final[Obesity_Prev],
                "Heart_Disease", master_county_final[Coronary_Heart_Disease_Prev]
            ) > MedianOutcome
        )
    )
VAR TotalCounties = CALCULATE(COUNTROWS(master_county_final), ALL(master_county_final))
RETURN
    DIVIDE(CountBoth, TotalCounties)
```

---

### Poverty Level
Calculated column that classifies each county into a poverty tier for use in the scatter plot legend.
```dax
Poverty Level = 
VAR P = master_county_final[PCT_Poverty]
RETURN
SWITCH(
    TRUE(),
    P < 10, "Low Poverty (Under 10%)",
    P < 20, "Moderate Poverty (10–20%)",
    P < 30, "High Poverty (20–30%)",
    "Very High Poverty (30%+)"
)
```

---

### State Avg Poverty
Population-weighted average poverty rate at state level.
```dax
State Avg Poverty = 
DIVIDE(
    SUMX(
        master_county_final,
        master_county_final[PCT_Poverty] * master_county_final[Total_Pop]
    ),
    SUM(master_county_final[Total_Pop])
) / 100
```

---

### State Avg Food Insecurity
Population-weighted average food insecurity rate at state level.
```dax
State Avg FoodInsecurity = 
DIVIDE(
    SUMX(
        master_county_final,
        master_county_final[Food_Insecurity_21_23] * master_county_final[Total_Pop]
    ),
    SUM(master_county_final[Total_Pop])
) / 100
```

---

## Page 3 — Statistical Predictors of Chronic Disease Outcomes

### Top Predictor
Returns the strongest predictor variable for the selected regression model.
```dax
Top Predictor = 
VAR SelectedModel = SELECTEDVALUE(Slicer_Table[Disease])
RETURN
SWITCH(
    SelectedModel,
    "Diabetes", "Poverty",
    "Obesity", "Age 65+",
    "Heart_Disease", "Age 65+"
)
```

---

### R²
Returns the R-squared value for the selected regression model.
```dax
R² = 
VAR SelectedModel = SELECTEDVALUE(Slicer_Table[Disease])
RETURN
SWITCH(
    SelectedModel,
    "Diabetes", 0.7082,
    "Obesity", 0.4625,
    "Heart_Disease", 0.7647
)
```

---

### Adjusted R²
Returns the adjusted R-squared value for the selected model, accounting for the number of predictors.
```dax
Adjusted R² = 
VAR SelectedModel = SELECTEDVALUE(Slicer_Table[Disease])
RETURN
SWITCH(
    SelectedModel,
    "Diabetes", 0.7074,
    "Obesity", 0.4610,
    "Heart_Disease", 0.7641
)
```

---

### No. of Significant Variables
Returns the number of statistically significant predictors for the selected model.
```dax
No. of Significant Variables = 
VAR SelectedModel = SELECTEDVALUE(Slicer_Table[Disease])
RETURN
SWITCH(
    SelectedModel,
    "Diabetes", 8,
    "Obesity", 7,
    "Heart_Disease", 9
)
```

---

### Regression Model
Maps internal model column names to readable display labels for the regression chart.
```dax
Regression Model = 
SWITCH(
    'Regression Results (2)'[model],
    "Diabetes_Beta", "Diabetes",
    "Obesity_Beta", "Obesity",
    "HD_Beta", "Heart Disease"
)
```

---

## Page 4 — County-Level Vulnerability & Performance Benchmarks

### Structural Health Burden Index
The composite vulnerability score. Averages the Z-scores for food insecurity, poverty, food access deprivation, and disease prevalence into a single standardized index. Higher scores indicate greater compounding risk.
```dax
Structural Health Burden Index = 
DIVIDE(
    master_county_final[Z_FI_Col] +
    master_county_final[Z_Poverty_Col] +
    master_county_final[Z_FoodAccess_Col] +
    master_county_final[Z_Disease_Col],
    4
)
```

---

### Z_FoodAccess_Col
Population-weighted Z-score for food access deprivation. Used as a component of the composite vulnerability index.
```dax
Z_FoodAccess_Col = 
VAR MeanFI =
    CALCULATE(
        DIVIDE(
            SUMX(master_county_final, master_county_final[PCT_Low_Access_1Mile] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR StdFI =
    CALCULATE(
        STDEV.P(master_county_final[PCT_Low_Access_1Mile]),
        ALL(master_county_final)
    )
RETURN
DIVIDE(master_county_final[PCT_Low_Access_1Mile] - MeanFI, StdFI)
```

---

### Leading Contributing Factor
For a selected county, identifies whether poverty, food insecurity, or food access is the dominant driver of vulnerability by comparing the absolute Z-scores of all three.
```dax
Leading Contributing Factor = 
IF(
    ISFILTERED(master_county_final[County]) && HASONEVALUE(master_county_final[County]),
    VAR FI = [FI_Z_Score]
    VAR Pov = [Poverty_ZScore]
    VAR FA = [FoodAccess_ZScore]
    VAR AbsFI = ABS(FI)
    VAR AbsPov = ABS(Pov)
    VAR AbsFA = ABS(FA)
    RETURN
    SWITCH(
        TRUE(),
        AbsPov >= AbsFI && AbsPov >= AbsFA, "Poverty",
        AbsFI >= AbsPov && AbsFI >= AbsFA, "Food Insecurity",
        AbsFA >= AbsPov && AbsFA >= AbsFI, "Food Access",
        "Undetermined"
    ),
    BLANK()
)
```

---

### Food Access Vulnerability Level
Classifies the selected county into a structural vulnerability tier based on its composite index score.
```dax
Food Access Vulnerability Level = 
IF(
    ISFILTERED(master_county_final[County]) && HASONEVALUE(master_county_final[County]),
    SWITCH(
        TRUE(),
        [Structural_Risk_Index] >= 1, "Very High Structural Vulnerability",
        [Structural_Risk_Index] >= 0.5, "High Structural Vulnerability",
        [Structural_Risk_Index] >= 0, "Moderate Structural Vulnerability",
        [Structural_Risk_Index] >= -0.5, "Low Structural Vulnerability",
        "Very Low Structural Vulnerability"
    ),
    BLANK()
)
```

---

### Health Risk Position Among Counties
Ranks the selected county against all 3,129 counties by its composite structural health burden score.
```dax
Health Risk Position Among Counties = 
IF(
    ISFILTERED(master_county_final[County]) && HASONEVALUE(master_county_final[County]),
    VAR CurrentCounty = SELECTEDVALUE(master_county_final[County])
    VAR AllCountiesTable = 
        ADDCOLUMNS(
            ALL(master_county_final[County]),
            "@AvgRisk", CALCULATE(
                AVERAGE(master_county_final[Structural Health Burden Index]),
                ALLEXCEPT(master_county_final, master_county_final[County])
            )
        )
    VAR CurrentCountyScore = 
        MAXX(FILTER(AllCountiesTable, master_county_final[County] = CurrentCounty), [@AvgRisk])
    RETURN
    RANKX(
        AllCountiesTable,
        [@AvgRisk],
        CurrentCountyScore,
        DESC,
        Dense
    ),
    BLANK()
)
```

---

### Difference from National Average (%)
For a selected county, calculates how far its disease prevalence sits above or below the national average as a percentage.
```dax
Difference from National Average (%) = 
IF(
    HASONEVALUE(master_county_final[County]),
    VAR CountyRate = [County Disease Prevalence (%)]
    VAR NationalRate =
        CALCULATE(
            DIVIDE(
                SUMX(
                    master_county_final,
                    SWITCH(
                        SELECTEDVALUE(Slicer_Table[Disease]),
                        "Diabetes", master_county_final[Diabetes_Prev],
                        "Obesity", master_county_final[Obesity_Prev],
                        "Heart_Disease", master_county_final[Coronary_Heart_Disease_Prev],
                        master_county_final[Diabetes_Prev]
                    ) * master_county_final[Total_Pop]
                ),
                SUM(master_county_final[Total_Pop])
            ),
            ALL(master_county_final)
        )
    RETURN
    DIVIDE(CountyRate - NationalRate, NationalRate) * 100,
    BLANK()
)
```

---

### County Disease Prevalence (%)
Population-weighted disease prevalence for the currently selected county and disease.
```dax
County Disease Prevalence (%) = 
VAR SelectedOutcome = SELECTEDVALUE('Slicer_Table'[Disease])
RETURN
SWITCH(
    SelectedOutcome,
    "Diabetes",
        DIVIDE(
            SUMX(master_county_final, master_county_final[Diabetes_Prev] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
    "Obesity",
        DIVIDE(
            SUMX(master_county_final, master_county_final[Obesity_Prev] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
    "Heart_Disease",
        DIVIDE(
            SUMX(master_county_final, master_county_final[Coronary_Heart_Disease_Prev] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        )
)
```

---

### Performance Relative to National Average
Benchmarks the selected county against the national average across four dimensions — disease rate, food access, food insecurity, and poverty. National benchmark is set to 100.
```dax
Performance Relative to National Average (%): Benchmark → (100) = 
VAR SelectedMetric = SELECTEDVALUE('County Benchmark'[Metric])
VAR SelectedType = SELECTEDVALUE('County Benchmark'[Level])

VAR NationalFI =
    CALCULATE(
        DIVIDE(
            SUMX(master_county_final, master_county_final[Food_Insecurity_21_23] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR NationalPov =
    CALCULATE(
        DIVIDE(
            SUMX(master_county_final, master_county_final[PCT_Poverty] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR NationalFA =
    CALCULATE(
        DIVIDE(
            SUMX(master_county_final, master_county_final[PCT_Low_Access_1Mile] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR NationalDis =
    CALCULATE(
        DIVIDE(
            SUMX(
                master_county_final,
                SWITCH(
                    SELECTEDVALUE(Slicer_Table[Disease]),
                    "Diabetes", master_county_final[Diabetes_Prev],
                    "Obesity", master_county_final[Obesity_Prev],
                    "Heart_Disease", master_county_final[Coronary_Heart_Disease_Prev],
                    master_county_final[Diabetes_Prev]
                ) * master_county_final[Total_Pop]
            ),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR CountyFI =
    DIVIDE(
        SUMX(master_county_final, master_county_final[Food_Insecurity_21_23] * master_county_final[Total_Pop]),
        SUM(master_county_final[Total_Pop])
    )
VAR CountyPov =
    DIVIDE(
        SUMX(master_county_final, master_county_final[PCT_Poverty] * master_county_final[Total_Pop]),
        SUM(master_county_final[Total_Pop])
    )
VAR CountyFA =
    DIVIDE(
        SUMX(master_county_final, master_county_final[PCT_Low_Access_1Mile] * master_county_final[Total_Pop]),
        SUM(master_county_final[Total_Pop])
    )
RETURN
SWITCH(
    TRUE(),
    SelectedMetric = "Food Insecurity" && SelectedType = "County",
        DIVIDE(CountyFI, NationalFI) * 100,
    SelectedMetric = "Food Insecurity" && SelectedType = "National",
        100,
    SelectedMetric = "Poverty" && SelectedType = "County",
        DIVIDE(CountyPov, NationalPov) * 100,
    SelectedMetric = "Poverty" && SelectedType = "National",
        100,
    SelectedMetric = "Food Access" && SelectedType = "County",
        DIVIDE(CountyFA, NationalFA) * 100,
    SelectedMetric = "Food Access" && SelectedType = "National",
        100,
    SelectedMetric = "Disease Rate" && SelectedType = "County",
        IF(
            HASONEVALUE(master_county_final[County]),
            DIVIDE([County Disease Prevalence (%)], NationalDis) * 100,
            100
        ),
    SelectedMetric = "Disease Rate" && SelectedType = "National",
        100
)
```

---

## Page 5 — Drivers of Food Access & Temporal Trends

### Population with Low Food Access
Population-weighted percentage of people living more than 1 mile from a grocery store nationally.
```dax
Population with Low Food Access = 
DIVIDE(
    SUMX(
        master_county_final,
        master_county_final[PCT_Low_Access_1Mile] * master_county_final[Total_Pop]
    ),
    SUM(master_county_final[Total_Pop])
)/100
```

---

### Food Insecurity After COVID (2021–2023)
Population-weighted national food insecurity rate for the post-COVID period.
```dax
Food Insecurity After COVID (2021–2023) = 
DIVIDE(
    SUMX(master_county_final, master_county_final[Food_Insecurity_21_23] * master_county_final[Total_Pop]),
    SUM(master_county_final[Total_Pop])
)/100
```

---

### Food Insecurity Before COVID (2018–2020)
Population-weighted national food insecurity rate for the pre-COVID period.
```dax
Food Insecurity Before COVID (2018–2020) = 
DIVIDE(
    SUMX(master_county_final, master_county_final[Food_Insecurity_18_20] * master_county_final[Total_Pop]),
    SUM(master_county_final[Total_Pop])
)/100
```

---

### Rise in Food Insecurity Post COVID
Difference between post-COVID and pre-COVID population-weighted food insecurity rates. The near-zero result reflects stability in large urban counties — unweighted the rise was 1.44 percentage points.
```dax
Rise in Food Insecurity Post COVID = 
[Food Insecurity After COVID (2021–2023)] - [Food Insecurity Before COVID (2018–2020)]
```

---

### FI By Period
Switches between pre and post-COVID food insecurity figures based on the period slicer selection.
```dax
FI_By_Period = 
SWITCH(
    SELECTEDVALUE(Time_Period[Period]),
    "Pre-COVID (2018–2020)", [Food Insecurity Before COVID (2018–2020)],
    "Post-COVID (2021–2023)", [Food Insecurity After COVID (2021–2023)]
)
```

---

### Store Growth
Returns grocery store growth rate for urban or rural areas based on the slicer selection.
```dax
Store_Growth = 
VAR SelectedGroup = SELECTEDVALUE('Store Growth'[Area])
RETURN
SWITCH(
    TRUE(),
    SelectedGroup = "Urban", [Avg_StoreGrowth_Urban],
    SelectedGroup = "Rural", [Avg_StoreGrowth_Rural]
)
```

---

## Supporting Calculated Columns

### Z_Poverty_Col
Population-weighted Z-score for poverty rate. Component of the composite vulnerability index.
```dax
Z_Poverty_Col = 
VAR MeanPov =
    CALCULATE(
        DIVIDE(
            SUMX(master_county_final, master_county_final[PCT_Poverty] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR StdPov =
    CALCULATE(
        STDEV.P(master_county_final[PCT_Poverty]),
        ALL(master_county_final)
    )
RETURN
DIVIDE(master_county_final[PCT_Poverty] - MeanPov, StdPov)
```

---

### Z Income
Population-weighted Z-score for median household income.
```dax
Z Income = 
VAR MeanFA =
    CALCULATE(
        DIVIDE(
            SUMX(master_county_final, master_county_final[Median_HH_Income] * master_county_final[Total_Pop]),
            SUM(master_county_final[Total_Pop])
        ),
        ALL(master_county_final)
    )
VAR StdFA =
    CALCULATE(
        STDEV.P(master_county_final[Median_HH_Income]),
        ALL(master_county_final)
    )
RETURN
DIVIDE(master_county_final[Median_HH_Income] - MeanFA, StdFA)
```

---

### Number of Urban / Rural Counties
Simple counts used for supporting calculations.
```dax
Number of Urban Counties = 
CALCULATE(
    DISTINCTCOUNT(master_county_final[County_FIPS_Fixed]),
    master_county_final[Urban] = 1
)

Number of Rural Counties = 
CALCULATE(
    DISTINCTCOUNT(master_county_final[County_FIPS_Fixed]),
    master_county_final[Urban] = 0
)
```
