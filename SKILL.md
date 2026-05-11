---
name: sci-paper-optimizer
description: General workflow for planning, writing, revising, and quality-controlling SCI research papers. Use when Codex is asked to improve manuscript logic, build a publishable story, organize results, align claims with evidence, reduce overstatement, prepare reviewer-ready methods and limitations, plan main/supplementary figures and tables, or set publication-quality scientific plotting standards for any research project.
---

# SCI Paper Optimizer

## Overview

Use this skill to turn a research project into a coherent, defensible SCI manuscript. Focus on argument structure, evidence traceability, cautious interpretation, reviewer risk reduction, reproducibility, and publication-quality figures.

## Core Rule

Do not make the paper broader than the evidence. Every strong claim must map to a result table, figure, analysis script, experiment, or citation. If the evidence is computational, correlative, preliminary, or candidate-level, keep the wording at that level.

## Reference Selection

Load only the reference needed for the task:

- For paper planning, story construction, section rewriting, and claim optimization, read `references/paper-writing-framework.md`.
- For figure design, chart selection, panel layout, color, typography, and main/supplementary figure decisions, read `references/figure-standard.md`.
- For statistical tests, error bars, P/FDR labels, significance stars, compact letters, and figure legends, read `references/statistical-annotation-standard.md`.
- For a unified visual identity, journal-inspired theme profiles, palettes, and plotting theme templates, read `references/figure-theme-styles.md`.
- For concrete R/ggplot2 code skeletons for common scientific figures, read `references/plot-recipes.md` and reuse `scripts/sci_plot_theme.R`.
- For plant-biology journal figure requirements and panel-composite assembly, read `references/panel-assembly-workflow.md`.
- For submission or reviewer-readiness checks, read `references/reviewer-readiness-checklist.md`.

## Manuscript Workflow

1. Identify the manuscript stage: idea planning, outline, first draft, section revision, figure/table integration, response to reviewers, or pre-submission audit.
2. Define the central claim in one sentence, then list the 3-5 evidence blocks that support it.
3. Arrange Results by logic, not by tool order. Each subsection should answer one scientific question and end with a restrained interpretation.
4. Classify each claim before editing:
   - Direct evidence: state plainly with exact numbers and methods.
   - Statistical association: use association, correlation, enrichment, coupling, or linked-to wording.
   - Candidate mechanism: call it a candidate, model, hypothesis, or proposed route.
   - Speculation: move to Discussion and mark as future work or a testable hypothesis.
5. Check that Methods describe inputs, preprocessing, thresholds, statistical models, controls, multiple-testing correction, and reproducibility enough for a reviewer to evaluate the work.
6. Preserve uncertainty. Limitations should narrow the claim without weakening the contribution.

## Figure Workflow

1. Write a figure brief before drawing: the claim, audience takeaway, data source, statistical display, main/supplementary placement, and expected panel size.
2. Choose the simplest chart type that shows comparison, magnitude, uncertainty, sample structure, and evidence level.
3. Define the statistical display before drawing: independent n, test/model, correction, interval, effect size, and annotation style.
4. Select one theme profile for the paper before producing final figures, then keep fonts, palettes, axes, line weights, legends, and panel labels consistent. For R figures, prefer `scripts/sci_plot_theme.R` over redefining theme and palette code.
5. Assign panels to main figures only if they carry the paper's central argument. Put QC, sensitivity, diagnostics, large candidate lists, and extended validations in supplementary figures/tables.
6. Use consistent visual grammar across the paper: same ordering, color meanings, fonts, labels, statistical annotations, and abbreviation policy.
7. Validate final exports at journal column width, not only inside the plotting environment, and confirm that the plotted evidence supports the exact Results claim.

## Audit Script

Use the bundled script for a generic manuscript triage:

```bash
python /data/users/chenming/.codex/skills/sci-paper-optimizer/scripts/audit_sci_paper.py \
  --manuscript path/to/manuscript.md
```

The script checks placeholders, risky overclaim wording, missing core sections, figure/table numbering density, and optional path hygiene. Treat it as a fast screen; still read the paper and source evidence.

Use the bundled figure-asset checker before calling figure previews or exported artwork ready:

```bash
python /data/users/chenming/.codex/skills/sci-paper-optimizer/scripts/check_figure_assets.py \
  /data/users/chenming/.codex/skills/sci-paper-optimizer
```

The checker verifies preview HTML references, unused preview leftovers, 0-byte files, non-ASCII paths, browser-risky SVG structures, visible NA labels, and likely white-as-data color scales.

## Response Style

When reviewing, lead with issues that could block publication: unsupported claims, causal overreach, missing controls, weak methods, figure unreadability, or traceability gaps. When editing, state what was changed, why it improves the scientific argument, and what remains dependent on author-supplied information.
