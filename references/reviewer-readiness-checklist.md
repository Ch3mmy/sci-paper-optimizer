# Reviewer Readiness Checklist

Use this reference before submission, before sending a draft to collaborators, or when reviewing a manuscript for publication risk.

## Review Order

1. Identify the target journal or article type if known.
2. Read title, abstract, figure titles, and subsection headings first. The story should be coherent from this layer alone.
3. Check each major claim against figures, tables, source analyses, experiments, or citations.
4. Inspect Methods for reproducibility and reviewer-evaluable detail.
5. Inspect figures at final export size.
6. Separate blocking issues from polish.

## Major Publication Risks

Flag these first:

- Central claim is broader than the data.
- Causal language is used for observational, computational, or correlative evidence.
- Controls, baselines, negative controls, or non-target comparisons are missing.
- Statistical tests, sample sizes, correction methods, or effect sizes are unclear.
- Results are organized by tool rather than scientific question.
- Figures are unreadable, overcrowded, or not linked to claims.
- Methods omit key inputs, thresholds, parameters, or software versions.
- Data/code availability is incomplete or fabricated.
- Limitations are absent or only generic.
- Literature framing ignores obvious competing explanations.

## Manuscript Checks

Search for:

- Placeholders such as `TODO`, `TBD`, `PLACEHOLDER`, or bracketed missing fields.
- Overclaim words: `prove`, `conclusively`, `demonstrate that X causes`, `drives`, `determines`, `master regulator`, `key mechanism`.
- Unqualified candidate language: predictions or computational calls stated as confirmed facts.
- Claims in abstract or discussion that never appear in Results.
- Percentages or counts without source tables.
- Figure/table references that are missing, duplicated, or out of order.
- Undefined abbreviations.
- Missing accession numbers, repository links, ethics approvals, acknowledgements, or funding details when required.

## Figure Checks

For each figure:

- What is the one message?
- Which Results claim does it support?
- Is there a figure brief naming the claim, data source, sample structure, statistical display, placement, and target size?
- Is it main-text worthy or supplementary?
- Is the chart type appropriate for the data?
- Are source panels label-free, with A/B/C or a/b/c labels added consistently only in the final composite?
- Are sample sizes, replicate types, uncertainty, effect sizes, statistical tests, and multiple-testing corrections shown or stated?
- Are significance stars, brackets, compact letters, P values, q values, and FDR thresholds tied to a documented test/model and source table?
- Are technical replicates, cells, reads, pixels, or genes not misrepresented as independent biological replicates?
- Are colors and category orders consistent across figures?
- Does the manuscript use one coherent paper-level figure theme for fonts, axes, palettes, panel labels, legends, and schematic evidence levels?
- Are axis limits, transformations, denominators, and units explicit enough to prevent misinterpretation?
- Are missing values, `NA` categories, and zero values handled correctly?
- Is text readable at final size?
- Can the legend explain the panel without repeating the whole Methods section?
- Can the source data, plotting script, and exported file be traced?

## Methods Checks

Confirm that Methods include:

- Data origin and sample design.
- Inclusion/exclusion rules.
- Preprocessing and quality control.
- Software, versions, and important parameters.
- Statistical models and correction methods.
- Definitions of independent n, replicate type, post hoc tests, and significance thresholds used in figures.
- Definitions of derived variables or candidate classes.
- Reproducibility path for scripts, tables, and figures.

## Review Output Format

Use this structure for a review response:

1. `Major issues`: publication-blocking logic, evidence, methods, or figure problems.
2. `Minor issues`: wording, consistency, formatting, or local clarity.
3. `Recommended revision plan`: ordered actions.
4. `Verification`: commands run, files checked, or checks still needed.

If no serious issues are found, say so directly and name the remaining residual risks.
