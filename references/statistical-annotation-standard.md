# Statistical Annotation Standard

Use this reference when adding statistical analysis, uncertainty displays, P values, FDR, significance marks, letters, or model estimates to scientific figures.

## Core Rule

Never add significance marks without a documented test, sample definition, correction method, and source table. Statistical marks are part of the evidence, not decoration.

## Figure Brief Additions

For any figure with statistical comparison, record:

| Field | Required answer |
| --- | --- |
| Biological unit | Plant, animal, patient, plot, cell line, library, cell, image, read, gene, or locus? |
| Independent n | What is the independent replicate used by the test? |
| Design | Independent groups, paired/repeated measures, time course, nested, blocked, factorial, or high-throughput? |
| Test/model | t-test, ANOVA, Wilcoxon, Kruskal-Wallis, mixed model, GLM, DESeq2, Fisher test, logistic regression, permutation, etc. |
| Correction | None justified, Tukey, Dunnett, Holm, Benjamini-Hochberg FDR, Bonferroni, q value, or empirical FDR? |
| Display | Raw points, mean ± SD/SEM/CI, median/IQR, model estimate ± CI, box/violin, coefficient plot, or FDR dot plot? |
| Annotation | Exact P/q, stars, compact letters, brackets, threshold lines, confidence intervals, or none? |
| Source | Which result table stores test statistics and adjusted values? |

## Choosing the Test or Model

Use this as a default decision guide, then adapt to the field and design:

| Design | Common choice | Figure display |
| --- | --- | --- |
| Two independent groups, roughly normal residuals | Welch t-test or linear model | Raw points + mean/CI or estimation plot |
| Two paired groups | Paired t-test or Wilcoxon signed-rank | Paired lines + difference/CI |
| More than two groups | ANOVA/linear model with Tukey or Dunnett post hoc | Raw points + compact letters or selected contrasts |
| Non-normal small n | Wilcoxon or Kruskal-Wallis with adjusted pairwise tests | Box/dot plot; avoid overclaiming distribution |
| Time course or repeated measures | Mixed model or repeated-measures model | Trajectory + CI; state subject/block random effects |
| Count/proportion | GLM, logistic/binomial model, Fisher exact, chi-square | Proportion plot + CI or odds-ratio forest plot |
| Enrichment | Fisher exact, hypergeometric, permutation, GSEA-style statistic | Dot/forest plot with effect size and FDR |
| Omics differential analysis | Domain method such as DESeq2/edgeR/limma/metilene | Volcano, MA, heatmap; show FDR and effect size |
| Correlation | Pearson/Spearman or model-based association | Scatter + fit/CI; state rho/r and P/FDR |
| Survival/time-to-event | Cox model, log-rank | Kaplan-Meier + HR/CI where relevant |

Do not choose the test only after seeing which one gives significance. If assumptions are uncertain, use a robust model or show sensitivity in supplements.

## Error Bars and Intervals

Define every interval in the legend:

- `mean ± SD`: variation among observations.
- `mean ± SEM`: precision of estimated mean; do not use it to imply biological spread.
- `mean ± 95% CI`: uncertainty in the estimate; often preferred for main comparisons.
- `median and IQR`: nonparametric distribution summary.
- `model estimate ± 95% CI`: use for regression, GLM, mixed models, odds ratios, hazard ratios, and contrasts.

Avoid unlabeled error bars. Reviewers often treat unlabeled error bars as a methods failure.

## Significance Annotation Style

Prefer exact adjusted values when space allows:

- `P = 0.032`
- `FDR = 0.018`
- `q = 0.041`
- `OR = 2.1, 95% CI 1.4-3.2`

Use stars only for simple comparisons where exact labels would clutter the panel:

| Mark | Conventional threshold |
| --- | --- |
| ns | P or q >= 0.05 |
| * | < 0.05 |
| ** | < 0.01 |
| *** | < 0.001 |
| **** | < 0.0001 |

If using stars:

- State in the legend whether thresholds apply to raw P, adjusted P, q, or FDR.
- Use the same thresholds throughout the manuscript.
- Do not mix one-sided and two-sided tests without explicit explanation.
- Do not place stars where they collide with data, error bars, axis labels, or panel letters.

## Brackets, Letters, and Labels

Use bracket annotations for a few planned pairwise contrasts. Avoid bracket stacks over many groups.

Use compact letter displays (`a`, `b`, `ab`) for many-group post hoc comparisons:

- Explain the rule in the legend: groups not sharing a letter differ at the stated adjusted threshold.
- State the model and post hoc correction.
- Keep letters close to the group summary but away from data points.
- Do not use compact letters when the comparison set is not all pairwise or not symmetric.

Use threshold lines for omics plots:

- Volcano plots: vertical effect-size cutoffs and horizontal FDR/P threshold lines.
- Enrichment/dot plots: use color for FDR/q and x-axis for effect or gene ratio.
- Heatmaps: avoid putting asterisks in every cell unless the matrix is small and the test is central.

## Sample Size and Replicate Marking

Always state the independent n in the legend or panel:

- `n = 5 biological replicates`
- `n = 3 independent experiments`
- `n = 12 plants`
- `n = 864 cells from 4 biological replicates`

Do not treat cells, reads, pixels, or genes as independent biological replicates unless the claim is explicitly about those units. For nested data, use a model or summary that respects the independent unit.

## Multiple Testing

Use correction when multiple hypotheses are tested:

- Pairwise comparisons after ANOVA: Tukey, Dunnett, Holm, or planned contrasts.
- Omics and high-throughput screens: Benjamini-Hochberg FDR or method-specific q values.
- Many panels sharing the same comparison family: define whether correction is per panel, per figure, or per analysis family.

Do not show raw P values as if they were final evidence when FDR is the inferential standard.

## Visual Placement

Statistical marks should be readable but secondary to the data:

- Leave vertical space above data before adding brackets or stars.
- Align repeated annotations consistently across similar panels.
- Use dark gray or black for marks; avoid bright colors unless marks encode different test families.
- Put full test details in the legend or source table, not inside the panel.
- For dense omics panels, put statistics in color, size, alpha, or side tables rather than text overplotting.

## Legend Requirements

Every statistical figure legend should include:

- Independent sample size and replicate type.
- Summary statistic and interval definition.
- Test/model name.
- Multiple-testing correction.
- Whether tests are one- or two-sided when relevant.
- Thresholds for stars, letters, or FDR categories.
- Software/package only when it matters for reproducibility or specialized methods.

Example legend sentence:

`Points show biological replicates; bars show mean ± 95% CI. P values were calculated with a two-sided Welch t-test and adjusted across the four planned contrasts using the Holm method.`

## Common Mistakes

- Showing SEM without defining it.
- Using stars without saying which test produced them.
- Treating technical replicates as independent biological n.
- Running all pairwise tests but reporting only significant ones.
- Applying no correction to many comparisons.
- Using bar plots for small-n biology without raw points.
- Reporting P < 0.05 while hiding effect size and uncertainty.
- Adding significance markers to visual differences that were not tested.
