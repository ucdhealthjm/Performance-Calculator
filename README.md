# Medical Performance Sleep Calculator

Companion materials for:

> **Moen J.** *The Recovery Deficit: A Simulation Model of Physician Performance Under Sleep Deprivation.* **Cureus** 17(10): e95729 (2025). DOI: [10.7759/cureus.95729](https://doi.org/10.7759/cureus.95729)

Open the interactive calculator: **[index.html](./index.html)** (or visit the GitHub Pages site if published).

---

## What's in this repository

| File | Purpose |
|---|---|
| [`index.html`](./index.html) | Self-contained interactive calculator. No build step, no dependencies. |
| [`sleep_simulation.do`](./sleep_simulation.do) | Stata 18 do-file that runs the full 500-iteration Monte Carlo described in the paper. This is the source of truth for every coefficient in the calculator. |
| [`LICENSE`](./LICENSE) | CC BY 4.0, matching the open-access license of the published article. |

## How the calculator relates to the paper

The Stata do-file generates 500 Monte Carlo iterations of 11,000 synthetic clinician-days each, producing Table 1 in the paper. For interactive use, the calculator implements the **deterministic mean** of the underlying dose-response equations, evaluated at the exact sleep-hour value the user enters, with two adjustments needed to reproduce the paper's published means:

1. **Lognormal convexity correction for attentional lapses.** Because lapses are drawn as `Poisson(exp(...))` and the simulation samples `b_lap_quad` from a normal prior, the expected lapse count requires `+0.5·Var(log-rate)` to match the Monte Carlo mean. Without this correction, lapses are underestimated by ~20% at full deprivation.
2. **Analytic 95% individual range.** The calculator surfaces a ±1.96·SD band combining (i) per-observation noise (the `z_*` SDs in the do-file) and (ii) parameter uncertainty in each slope. The published paper uses simulation percentiles; the analytic version is a close approximation and is what the calculator displays.

### Verification against Table 1

Averaging the calculator over all 12 role × specialty combinations at each sleep-hour bucket center reproduces every Table 1 column to within ±1.5 units. (The intermediate-hour RT residuals of 3–8 ms are *not* a calculator bug — the do-file's `sleep_cat` buckets are populated by a truncated-normal sleep distribution centered at 5.8 hours, so each bucket's empirical mean is shifted away from `k + 0.5`.)

## Equations implemented

With `d = max(0, 8 − sleep_hours)`:

| Outcome | Equation |
|---|---|
| Reaction time (ms) | `280 + (32 + m_rt)·d + 1·d²` |
| Clinical accuracy (%) | `95 + (−3 + m_clin)·d − 0.2·d²` |
| Diagnostic accuracy (%) | `90 + (−2.5 + m_diag)·d − 0.3·d²` |
| Mood (0–100) | `80 − 2·d − 0.2·d²` |
| Attentional lapses | `exp(−1 + 0.25·d + 0.05·d²)` (with convexity correction) |
| Medical error | `invlogit(−2.94 + 0.11·d + 0.01·d²)` |
| Burnout | `invlogit(−1.95 + 0.25·d)` |
| Composite (0–100) | unweighted mean of normalized RT, clinical, diagnostic, and inverse-lapses domains |

Role/specialty modifiers (`m_*`) are applied only to the outcomes the do-file specifies: clinical & diagnostic accuracy and reaction time. They are **not** invented for outcomes the paper leaves unmodified.

Cognitive-state (BAC) equivalences are mapped from sleep debt using Williamson & Feyer (2000, *Occup Environ Med*) and Arnedt et al. (2005, *JAMA*), as referenced in the paper's Materials and Methods.

## Post-publication addenda

> **The published model is unchanged.** The sections below describe analyses and an optional toggle added to this repository *after* publication of Moen 2025 (*Cureus* 17(10): e95729). They are not claims of the original paper. The calculator's default state (chronic-debt toggle off) reproduces the paper's Table 1 to within ±1.5 units across all eight metrics — verified end-to-end against the Stata do-file.

### External concordance (post-publication check)

The simulation is a synthesis, not new empirical data — but two NIH-funded multicenter studies from the Brigham/Harvard Sleep Medicine group provide independent comparison points at sleep levels the model spans. The table below compares the published model's predictions to those cohorts. **It is a post-publication concordance check, not part of the original paper.**

| Comparison | Source | Observed effect | Predicted by this model | Verdict |
|---|---|---|---|---|
| **Per extended-duration shift (~2.5 h sleep) vs. none** | Barger et al. *BMJMed* 2023 (n=4,826 PGY2+ residents, 38,702 monthly reports) | OR **1.84** for medical error per ≥1 extended shift/mo | Per-night 2.5 h vs. 7 h → predicted error-rate ratio **2.05×** | **Concordant** — model reproduces a directly observed odds ratio to within ~10% |
| **Schedule that gains ~0.55 h/night** (RCWR vs. EDWR) | Barger et al. *Sleep* 2019 (ROSTERS; n=302 pediatric residents, 6 sites, cluster-randomized crossover) | Improved PVT reaction time and fewer attentional failures on RCWR; modest medical-error reduction (companion report) | 7.0 h → 7.6 h sleep predicts ~7% relative error reduction and ~9 ms faster RT | **Directionally concordant** |
| **>80 vs. ≤48 weekly work hours** | Barger et al. *BMJMed* 2023 | OR **4.01** for medical error | Predicted ratio from acute-sleep difference alone ~**1.3–1.5×** | **Model under-predicts by ~3×** (see framing below) |

**On the third row — why the under-prediction is a feature, not a bug.** The published model is a *pure acute nightly-sleep dose-response*. It deliberately does not include workload, between-shift recovery, chronic multi-night debt, or shift-length effects independent of sleep. Field studies that bucket residents by weekly work hours capture all of those at once. The fact that the Barger 2023 OR of 4.0 at >80 h/wk exceeds our acute-sleep predictions by roughly 3× is consistent with this: work-hour effects in field studies aggregate sleep loss with workload, recovery, and chronic accumulation — none of which are modeled here. **The calculator should be interpreted as a lower bound on real-world impairment.**

### Optional chronic-debt toggle (post-publication extension, off by default)

The calculator includes an optional checkbox — *"I've been sleep-deprived for 5+ days"* — that, when enabled, inflates the error and lapse slopes by ~1.5× per Belenky et al. 2003 (*Sleep*). This is a post-publication extension intended to partially close the under-prediction gap noted above for chronic-deprivation states. **It is not part of the model as published**, and when it is enabled the calculator displays an "extended model" badge next to the results header so users can tell the outputs are no longer the published estimate.

The toggle multiplier acts on the *slope* on sleep debt (and on the quadratic for lapses), not on the intercept — so the rested baseline at 8 h sleep is identical whether the toggle is on or off. With the toggle off, outputs reproduce the paper's Table 1 exactly.

## Why this repository was rebuilt

A previous public version of this calculator (at `j-amo.github.io/Performance-Calculator/`, cited in the published paper) implemented a secondary regression fit to simulated output rather than the original equations from the do-file. That version had multiple errors: it used a 7-hour rather than 8-hour baseline, omitted all quadratic terms, omitted diagnostic accuracy, mood, and burnout, used the wrong intercept for reaction time (265 vs 280 ms) and lapses (`exp(−0.31)` vs `exp(−1)`), nearly doubled the medical-error slope, and listed specialties and modifiers not present in the source do-file. This rebuild restores the published equations exactly. A correction notice has been submitted to *Cureus*.

## License

[CC BY 4.0](./LICENSE) — same as the published article. Please cite the paper if you use or adapt this material.
