# Medical Performance Sleep Calculator

Interactive companion to:

**Moen J. The Recovery Deficit: A Simulation Model of Physician Performance Under Sleep Deprivation. *Cureus* 17(10): e95729 (2025).** [doi:10.7759/cureus.95729](https://doi.org/10.7759/cureus.95729)

**Open the calculator:** https://ucdhealthjm.github.io/Performance-Calculator/

## Files

- `index.html`: the calculator. A single self-contained page with no build step or dependencies.
- `sleep_simulation.do`: the Stata 18 do-file for the Monte Carlo simulation described in the article.
- `LICENSE`: CC BY 4.0.

## About the calculator

The calculator shows model means at the exact sleep duration entered (0 to 8 hours), compared with an eight-hour rested baseline. The article groups sleep into hourly categories, so values at a specific hour can differ from the article's table. Ranges reflect the model's parameter and observation variability; they are not confidence intervals for real-world clinical risk.

Results are an illustration of a simulation model using synthetic data. They are not personal estimates of medical error, burnout, clinical competence, or fitness for duty.

## License

[CC BY 4.0](./LICENSE). Please cite the article if you use or adapt this material.
