
********************************************************************************
* Medical Performance Impact Simulation - Publication Quality Monte Carlo
* Final Polished Version
* Date: 8 Sept 2025
********************************************************************************
clear all
version 18.0
********************************************************************************
* SECTION 1: PARAMETER CATALOG & MONTE CARLO SETUP
********************************************************************************
* -- Main Settings --
* Set the number of Monte Carlo repetitions
local R 500
* Note: R=500 balances stability and runtime; results are stable by R~300-500.
* Set toggle for optional detailed calibration run (0=off, 1=on)
local detailed_cal 0
* -- Parameter Catalog --
* Define means (mu) and standard deviations (sd) for literature-based parameters
local mu_rt 32
local sd_rt = (37-27)/3.92
local mu_clin -3
local sd_clin = (3.5-2.5)/3.92
local mu_diag -2.5
local sd_diag = (3.0-2.0)/3.92
local mu_err 0.11
local sd_err = (0.14-0.095)/3.92
local mu_burn 0.25
local sd_burn = (0.30-0.20)/3.92
local mu_mood -2
local sd_mood = (2.5-1.5)/3.92
local mu_lap_quad 0.05
local sd_lap_quad = (0.07-0.03)/3.92
* -- Pre-computation for Stability --
* Calculate a stable 99th percentile for lapses on a large sample
preserve
clear
set seed 12345
set obs 200000
gen sleep_debt = round(runiform()*8, 0.1)
gen laps_lambda = exp(-1 + 0.25*sleep_debt + `mu_lap_quad'*sleep_debt^2 + rnormal(0,0.4))
gen laps_central = rpoisson(laps_lambda)
_pctile laps_central, p(99)
scalar lapmax_fixed = r(r1)
restore
* -- File Setup --
* Create a temporary file to store results from each repetition
tempfile aggregate_results
save `aggregate_results', emptyok replace
********************************************************************************
* SECTION 2: SIMULATION LOOP
********************************************************************************
forvalues r = 1/`R' {
quietly {
clear
set seed `=54321 + `r''
set obs 11000
* Draw a new set of evidence-based parameters for this single repetition
scalar b_rt = rnormal(`mu_rt', `sd_rt')
scalar b_clin = rnormal(`mu_clin', `sd_clin')
scalar b_diag = rnormal(`mu_diag', `sd_diag')
scalar b_err = rnormal(`mu_err', `sd_err')
scalar b_burn = rnormal(`mu_burn', `sd_burn')
scalar b_mood = rnormal(`mu_mood', `sd_mood')
scalar b_lap_quad = rnormal(`mu_lap_quad', `sd_lap_quad')
* Sleep model
gen sleep_hours = round(rnormal(5.8,1.2),0.1)
replace sleep_hours = min(max(sleep_hours,0),9)
gen sleep_debt = max(0, 8 - sleep_hours)
replace sleep_hours = 0 in 10001/11000
replace sleep_debt = 8 in 10001/11000
* Roles & Specialties
gen role = runiformint(1,3)
label define role_lab 1 "Student" 2 "Resident" 3 "Attending"
label values role role_lab
gen specialty = runiformint(1,4)
label define spec_lab 1 "Emergency" 2 "Surgery" 3 "Internal Med" 4 "Psychiatry"
label values specialty spec_lab
* Shared correlated error terms
matrix R = (1,0.4,0.4,0.5,0.3,0.3,0.3 \ 0.4,1,0.5,0.4,0.3,0.3,0.3 \ 0.4,0.5,1,0.4,0.3,0.3,0.3 \ 0.5,0.4,0.4,1,0.3,0.3,0.3 \ 0.3,0.3,0.3,0.3,1,0.5,0.5 \ 0.3,0.3,0.3,0.3,0.5,1,0.5 \ 0.3,0.3,0.3,0.3,0.5,0.5,1)
drawnorm z_rt z_diag z_clin z_lap z_err z_mood z_burn, corr(R) n(11000)
* Justification: Small modifiers added for Student/Attending to model experience effects.
gen diag_central = 90 + (b_diag + cond(role==1,-0.5,0) + cond(role==3,0.5,0))*sleep_debt - 0.3*sleep_debt^2 + 3*z_diag
* Justification: Modifiers reflect literature on technical skill degradation (Surgery) and compensation (Attending).
gen clin_central = 95 + (b_clin + cond(specialty==2,-1,0) + cond(role==1,-0.5,0) + cond(role==3,1,0))*sleep_debt - 0.2*sleep_debt^2 + 4*z_clin

* Other performance models
gen rt_central = 280 + (b_rt + cond(role==3,-2,0) + cond(specialty==1,4,0))*sleep_debt + 1*sleep_debt^2 + 20*z_rt
gen laps_lambda = exp(-1 + 0.25*sleep_debt + b_lap_quad*sleep_debt^2 + 0.4*z_lap)
gen laps_central = rpoisson(laps_lambda)
gen err_p = invlogit(-2.94 + b_err*sleep_debt + 0.01*sleep_debt^2 + 0.3*z_err)
gen err_central = runiform() < err_p
gen burnout_p = invlogit(-1.95 + b_burn*sleep_debt + 0.3*z_burn)
gen burnout_central = runiform() < burnout_p
gen mood_central = 80 + b_mood*sleep_debt - 0.2*sleep_debt^2 + 5*z_mood
* Sleep categories
gen sleep_cat = floor(sleep_hours)
replace sleep_cat = 8 if sleep_hours>=8
label define scat 0 "0h" 1 "1h" 2 "2h" 3 "3h" 4 "4h" 5 "5h" 6 "6h" 7 "7h" 8 "8h+", replace
label values sleep_cat scat
* Normalization
gen norm_rt = (600 - rt_central)/(600-200)*100
replace norm_rt = max(0, min(100, norm_rt))
gen norm_clin = (clin_central - 60)/(100-60)*100
replace norm_clin = max(0, min(100, norm_clin))
gen norm_laps = (lapmax_fixed - laps_central)/lapmax_fixed*100
replace norm_laps = max(0, min(100, norm_laps))
gen norm_diag = (diag_central - 70)/30*100
replace norm_diag = max(0, min(100, norm_diag))
gen norm_burnout = 100*(1-burnout_central)
gen norm_mood = mood_central
replace norm_mood = max(0, min(100, norm_mood))
* Composite score
gen overall_score = (norm_clin + norm_rt + norm_laps + norm_diag)/4
* CORRECTED: Keep all necessary variables for the final analysis
collapse (mean) overall_score norm_clin norm_diag norm_laps err_central norm_rt norm_burnout norm_mood, by(sleep_cat)
* Append and save the results for this repetition
append using `aggregate_results'
save `aggregate_results', replace
}
}
********************************************************************************
* SECTION 3: ANALYSIS & VISUALIZATION (REVISED FOR BASELINE DEFICITS)
********************************************************************************
use `aggregate_results', clear
* Collapse the R repetitions to get the raw mean scores
* CORRECTED: Keep all variables needed for plotting AND calibration
collapse (mean) mean_score=overall_score mean_err=err_central (p3) p3_score=overall_score (p97) p97_score=overall_score, by(sleep_cat)
* --- NEW: CAPTURE THE RESTED BASELINE SCORE ---
* Find the mean score for the 8h+ sleep category
summarize mean_score if sleep_cat == 8
* Store this value in a scalar for easy use
scalar rested_baseline = r(mean)
* --- NEW: CREATE PERFORMANCE-AS-PERCENTAGE VARIABLES ---
* Calculate performance as a percentage of the rested baseline
gen performance_percent = (mean_score / rested_baseline) * 100
* Do the same for the confidence interval bounds
gen p3_percent = (p3_score / rested_baseline) * 100
gen p97_percent = (p97_score / rested_baseline) * 100
* Re-apply labels for clear plots
label values sleep_cat scat
* List the new, re-baselined results
list sleep_cat mean_score performance_percent, separator(0)
* --- UPDATED PLOT ---
* Plot the new percentage-based variables
twoway (rarea p3_percent p97_percent sleep_cat, color(gs14) fintensity(30)) (line performance_percent sleep_cat, lcolor(navy) lwidth(medthick)), xtitle("Hours of Sleep") ytitle("Performance (% of Rested Baseline)") title("Simulated Performance Deficit by Sleep", span) legend(off)
********************************************************************************
* SECTION 4: SUMMARY CALIBRATION CHECKS
********************************************************************************
di ""
di "****************** SUMMARY CALIBRATION CHECKS ******************"
* Calibration 1: Check rested baseline performance score
summ mean_score if sleep_cat == 8
di "Rested Performance Score (Sleep >= 8h): " r(mean) " (Target: ~95-100)"
* Calibration 2: Check error rate at ~4h sleep debt (4h of sleep)
summ mean_err if sleep_cat == 4
di "Error Rate at 4h Sleep: " r(mean)*100 "%"
* Calibration 3: Check severe deficit performance
summ mean_score if sleep_cat == 0
di "Total Deprivation Performance Score (Sleep = 0h): " r(mean)
********************************************************************************
* SECTION 5: OPTIONAL DETAILED CALIBRATION
********************************************************************************
if `detailed_cal' {
di ""
di "****************** DETAILED CALIBRATION RUN ******************"
clear
set seed 24680
set obs 200000
* Use fixed parameters (literature means) for a large reference run
scalar b_rt = `mu_rt'
scalar b_err = `mu_err'
scalar b_lap_quad = `mu_lap_quad'
* Generate data
gen sleep_hours = round(rnormal(5.8,1.2),0.1)
replace sleep_hours = min(max(sleep_hours,0),9)
gen sleep_debt = max(0, 8 - sleep_hours)
drawnorm z_rt z_lap z_err, corr((1,0.5,0.3 \ 0.5,1,0.3 \ 0.3,0.3,1)) n(_N)
gen rt_central = 280 + (b_rt)*sleep_debt + 1*sleep_debt^2 + 20*z_rt
gen laps_lambda = exp(-1 + 0.25*sleep_debt + b_lap_quad*sleep_debt^2 + 0.4*z_lap)
gen laps_central = rpoisson(laps_lambda)
gen err_p = invlogit(-2.94 + b_err*sleep_debt + 0.01*sleep_debt^2 + 0.3*z_err)
gen err = runiform() < err_p
di ""
di "--- Calibration: Rested RT (sleep_debt<=0.5) ---"
summ rt_central if sleep_debt<=0.5, detail
di ""
di "--- Calibration: Lapses at Total Deprivation (sleep_debt in [7.5,8.5]) ---"
summ laps_central if inrange(sleep_debt,7.5,8.5), detail
di ""
di "--- Calibration: Recovered error log-odds per hour debt ---"
logit err c.sleep_debt
di "Log-odds per hour of sleep debt should be close to `mu_err'"
}
********************************************************************************
* End of File
********************************************************************************

