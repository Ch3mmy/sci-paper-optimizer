# Scientific Figure Quality Standard

Use this reference when planning, reviewing, or redrawing figures for an SCI manuscript. The goal is not only to make figures attractive, but to make them accurate, readable, defensible, and directly tied to the paper's argument.

## Figure Brief

Before drawing a figure or panel, write a short brief:

| Field | Required answer |
| --- | --- |
| Claim | What exact Results sentence will this panel support? |
| Takeaway | What should a reader learn in 5 seconds? |
| Evidence role | Main evidence, support, control, QC, sensitivity, candidate list, or model? |
| Data source | Which table, script, experiment, or dataset generates the values? |
| Sample structure | What are n, replicates, pairing, batches, time points, species, cohorts, or treatments? |
| Statistical display | What uncertainty, effect size, P value, FDR, model coefficient, or test belongs on the plot? |
| Placement | Main figure or supplementary figure/table? |
| Target size | Single-column, double-column, or supplementary wide layout? |

If the brief cannot name a claim and data source, do not draw the panel yet.

## Main vs Supplementary Decision

Use a main figure when the panel is required for the central argument:

- It introduces the study system, design, cohort, dataset, or model.
- It establishes the primary phenomenon.
- It explains mechanism, comparison, prioritization, or interpretation.
- It provides a control without which the main claim would be hard to trust.
- It summarizes the final model or conceptual contribution.

Use supplementary figures or tables when the panel is supporting evidence:

- QC, diagnostics, mapping quality, filtering, or sample clustering.
- Parameter sensitivity or alternative thresholds.
- Extended candidate lists or full enrichment outputs.
- Caller, method, or pipeline concordance.
- Dense tables that would interrupt the main narrative.
- Reproducibility details needed by reviewers but not by first-pass readers.

Main figures should answer the paper's major questions. Supplementary figures should protect the credibility of those answers.

## Chart Selection

Choose the chart from the data question, not from habit:

| Question | Preferred chart | Avoid |
| --- | --- | --- |
| Ordered stage, dose, time, or trajectory | Line plot, point-range plot, slope plot, compact heatmap | Unordered bars |
| Two or more group comparisons | Dot plot with interval, box/violin with raw points, estimation plot | Bar-only mean plots |
| Many groups with one metric | Horizontal dot/bar plot ordered by effect | Alphabetical order without meaning |
| Composition or fate proportions | Stacked bar when totals matter, mosaic/tile summary, dot plot of proportions | Pie chart for many categories |
| Model coefficients or associations | Coefficient plot with CI, forest plot | Stars without effect sizes |
| Enrichment, odds ratio, risk ratio | Forest plot or dot plot with effect size and FDR | P-value-only bar plot |
| Matrix, correlation, expression, methylation, distance | Heatmap with meaningful ordering and scale | Heatmap without scale or uncontrolled clustering |
| Evidence hierarchy or candidate status | Ordered tile matrix with legend | Text-heavy table screenshot |
| Network or flow | Simplified network, sankey/alluvial only if paths are few and readable | Dense hairball networks |
| Mechanistic or conceptual model | Restrained schematic with evidence-level labels | Decorative infographic without evidence labels |

Prefer charts that show the raw data or effect size. Use summary-only displays only when raw points are too dense and the distribution is otherwise clear.

## Common Biology Figure Types

Use these defaults for biological, biomedical, omics, ecology, and experimental figures:

| Figure type | Best use | Required elements | Common failure |
| --- | --- | --- | --- |
| Column/bar plot | Small number of groups with clear aggregate values | Raw points when possible, n, error definition, test in legend | Bar-only mean plots hiding distribution |
| Line plot | Time course, dose response, developmental stage, ordered gradient | Ordered x-axis, points at observations, CI/SD/SEM ribbon or bars | Treating unordered categories as a trend |
| Horizontal bar plot | Ranking pathways, taxa, features, enriched terms, top candidates | Ordered by effect or score, readable labels, FDR/effect shown | Alphabetical bars and long clipped labels |
| Heatmap | Expression, methylation, correlation, distance, evidence matrix | Colorbar with units/scale, row/column order, missing-value color | Uncontrolled clustering that breaks biology |
| Boxplot | Distribution comparison with moderate n | Raw points or sample counts, median/IQR meaning | Using boxplot for n too small to estimate distribution |
| Violin plot | Distribution shape with enough observations | Raw points or inner summary, same bandwidth policy | Decorative violins for tiny n |
| Radar/spider plot | Compact multimetric profile across few groups | Same scale per axis, few variables, not used for precise comparison | Too many axes or groups, impossible quantitative reading |
| Alluvial/Sankey | Category fate, cell-state transitions, cluster reassignment, evidence-flow summary | Explicit denominators, few stages/classes, ordered flows | Too many crossings and unreadable thin streams |
| Volcano plot | Differential expression, methylation, proteomics, screening | Effect size axis, significance axis, thresholds, labelled top features | Treating significance as effect size |
| PCA/UMAP/t-SNE | Sample or cell-level structure and batch/treatment separation | Explain input features, distance/model, batch/group encoding | Overinterpreting unsupervised separation as mechanism |
| Dot/bubble plot | Enrichment, pathway activity, multi-metric summary | Dot size and color scales defined, FDR/effect separate | Unlabelled size scale or redundant encodings |
| Forest/coefficient plot | Odds ratios, hazard ratios, regression coefficients, meta-analysis | CI, null line, model/adjustment notes | Stars without uncertainty intervals |
| Microscopy/photo panel | Morphology, localization, anatomy, staining, phenotype | Scale bar, representative/quantitative link, acquisition notes | Missing scale bars or only cherry-picked images |

For main figures, prefer one chart type per evidence question. Do not include every chart type simply because it exists.

For concrete R/ggplot2 skeletons for these chart types, read `plot-recipes.md`
and reuse `../scripts/sci_plot_theme.R` instead of rebuilding theme and palette
code ad hoc.

## Faceted and Multi-Context Figures

Use faceting when the same question must be compared across species, tissues,
developmental stages, treatments, methylation contexts, omics layers, or
experimental batches.

- Facet only comparable panels that share the same x/y meaning and statistical unit.
- Keep row/column facets semantic: for example rows = species, columns = CG/CHG/CHH;
  or rows = tissue, columns = treatment. Avoid arbitrary facet order.
- Use shared axes when absolute magnitudes are being compared. Use free axes only for
  exploratory supplements and label that choice clearly.
- Keep color meanings stable across facets. Do not recolor the same species or context
  differently in different panels.
- Use strip labels as compact headers, not subtitles. Species names should be italicized
  in final exports when the plotting system supports parsed labels.
- For multi-species comparisons, combine color with facet, shape, or line type when the
  comparison is central; color alone is often insufficient after resizing.
- For multi-context assays such as methylation, keep context order fixed as `CG`, `CHG`,
  `CHH` unless the biological question requires another order.
- Do not facet so densely that each panel becomes unreadable at final journal width.
  If more than 6-8 small panels are needed, move the complete grid to supplementary
  figures and keep a focused subset in the main figure.

## Epigenomics Figure Patterns

For methylation, TE, sRNA, chromatin, and RdDM-style analyses, legends and encodings
must make the data layer explicit.

| Data layer | Recommended display | Required legend elements |
| --- | --- | --- |
| Methylation contexts | Faceted line/box/heatmap by `CG`, `CHG`, `CHH` | Context colors, scale as percentage or beta value, stage/tissue/species order |
| DMRs | Volcano, MA-style plot, effect-size forest, or genomic track | Hyper/hypo direction, effect threshold, FDR threshold, caller/method |
| TE overlap | Genome tracks, stacked proportions, enrichment forest plot | TE class/superfamily colors, denominator, overlap rule |
| 24-nt siRNA/sRNA | Genome track, metaplot, locus heatmap, caller concordance | Size class, strand policy if relevant, normalization unit |
| RdDM machinery | Expression/evidence matrix or model schematic | Candidate/observed/inferred status and whether evidence is association or mechanism |

Avoid using white as a meaningful data color in heatmaps, DMR status, or annotation
tracks; reserve white for background. Use light gray for midpoints or missing values
when a neutral class is required.

## Panel Labels, Titles, and Subtitles

High-level journal practice favors clean panels plus strong legends:

- Keep source panels label-free whenever possible. Add `A`, `B`, `C`, etc. only during final assembly so panel order can be changed without editing the source panels.
- In final composite figures, place panel letters consistently at the upper-left of each panel or just outside the panel boundary, following the target journal's case convention.
- Do not put `Figure 1A` inside the panel; use only the letter.
- Do not give every panel a long in-panel title and subtitle by default. They consume space and often duplicate the legend.
- Use short in-panel headers only when they are needed to decode the layout, such as `Control`, `Treatment`, `RNA-seq`, `WGBS`, `Early`, `Late`, or tissue names.
- Put the figure-level title and panel descriptions in the figure legend. The legend should briefly describe panel A, panel B, panel C in order.
- For internal draft previews, short titles/subtitles are acceptable to explain style. Remove or reduce them for final journal figures.
- Graphical abstracts are a separate case: they may need larger labels and self-contained narrative text, but they are usually single-panel and not a substitute for data figures.

Practical default: single-panel exports should have axis labels, units, legends, scale bars, and necessary group headers, but no `A/B/C/D` marks. Final composite figures should add panel letters in a separate assembly step. The explanatory title/subtitle belongs in the caption, not inside every panel.

## Plant-Biology Journal Standards

Common plant-science journals converge on these practical requirements:

- Submit each main figure as one file containing all its panels after acceptance or final production.
- Keep figure legends in the manuscript file, not embedded as long text inside figure panels.
- Use consistent fonts, panel labels, line weights, symbols, and spacing across all figures.
- Keep multi-panel figures logically connected; avoid very large figures with many weakly related panels.
- Use final-size or near-final-size artwork. Do not rely on later resizing to fix readability.
- Typical final widths are about 86 mm single column and 178 mm double column, with journal-specific variation.
- Raster images generally require at least 300-350 dpi at final printed size; line art often requires 600-1200 dpi or vector formats.
- Micrographs and phenotype photos should include scale bars where relevant.
- For multipanel figures, panel letters may be uppercase or lowercase depending on journal style; follow the target journal, but add these letters at the composite stage.

Examples from current author guidance: Plant and Cell Physiology uses 86 mm single-column and 178 mm double-column widths and asks panel labels to sit outside the figure area where possible; Journal of Experimental Botany recommends capital panel labels, 8-10 pt internal labels, and logically connected panels; Plant Physiology requires all panels of a multi-panel figure as one file and panel letters in the upper-left of each panel.

## Statistical Display Rules

Make the statistical layer explicit:

- Show sample size or state it in the legend when interpretation depends on n.
- Distinguish biological replicates, technical replicates, pooled samples, and repeated measures.
- Use SD for dispersion, SEM for precision of the mean, and CI for uncertainty in an estimate. Do not mix them without explanation.
- For paired or repeated designs, show pairing when possible or state the model used.
- Show effect sizes for important comparisons, not only P values.
- Use adjusted P values or FDR when many tests are performed.
- Label significance thresholds only if the Methods define the test and correction.
- Avoid causal wording in labels unless the experiment supports causality.
- Do not hide failed, null, or boundary results if they are necessary to judge the claim.

For omics, imaging, screening, or model-heavy papers, prioritize effect size plus uncertainty or FDR over isolated significance stars.

For detailed rules on test choice, independent n, error bars, stars, brackets, compact letters, FDR labels, and legend wording, read `statistical-annotation-standard.md`.

## Visual Encoding

Use visual channels consistently:

- Color should encode biological group, treatment, evidence level, model class, or effect direction.
- Keep color meanings stable across all figures.
- Use colorblind-aware palettes and test grayscale readability for key contrasts.
- Pair color with shape, line type, label, or facet when the category is central.
- Use diverging palettes only when there is a meaningful zero or reference point.
- Use sequential palettes for ordered magnitude and qualitative palettes for unordered categories.
- Do not use color for decoration if it competes with the data.
- Do not let `NA`, blank strings, or technical missingness appear as biological categories.

Common stable encodings:

- Control/reference before treatment/focal group.
- Early before late, low before high, untreated before treated.
- Confirmed evidence visually stronger than candidate or hypothesized evidence.
- Negative and positive effects placed on opposite sides of a neutral scale.

## Theme Consistency

Before final figure production, choose one paper-level theme and apply it across all figures. For journal-inspired theme profiles, palettes, and R/Python templates, read `figure-theme-styles.md`.

A theme should define:

- Font family and minimum final font size.
- Axis line width, tick length, grid policy, and background.
- Palette for categorical groups, sequential values, diverging effects, and neutral elements.
- Legend placement and key size.
- Panel label style.
- Standard figure widths and aspect ratios.
- Rules for heatmaps, dot plots, model schematics, and microscopy/image panels.

Do not mix unrelated themes within one manuscript unless the journal requires separate graphical abstract styling.

## Typography and Labels

Text must survive final export size:

- Validate at the target journal width, not in the plotting preview.
- Use short, message-oriented panel titles.
- Keep axis titles concrete and include units.
- Define abbreviations in legends unless they are universal for the field.
- Wrap or abbreviate long labels; move long gene, pathway, taxon, or candidate names into tables when needed.
- Avoid rotated labels beyond 45 degrees unless there is no better layout.
- Keep label vocabulary identical between Results, legends, and Methods.
- Do not put paragraphs inside a panel.

Minimum practical guidance:

- Single-column figure: use larger labels and fewer categories.
- Double-column figure: reserve width for heatmaps, matrices, multi-panel comparisons, or complex legends.
- Supplementary wide figure: acceptable for complete diagnostics, but still readable.

## Layout and Panel Assembly

Design the figure as a reader pathway:

- Place panels in the order they are discussed.
- Keep one message per panel.
- Align margins, axes, legends, facet labels, and panel letters.
- Use shared axes when panels are directly comparable.
- Keep legends close to the data they decode, but outside the plot body when they obscure values.
- Use whitespace deliberately; do not fill every open area with labels or decoration.
- Avoid heavy borders, nested boxes, ornamental gradients, background textures, and 3D effects.
- If a panel requires a long explanation to be understood, simplify it or move detail to supplementary material.
- Assemble final multi-panel figures from label-free panel exports using a reproducible manifest or assembly script. For the recommended workflow, read `panel-assembly-workflow.md`.

Typical sizes:

- Single-column: about 85-90 mm wide.
- Double-column: about 170-180 mm wide.
- Use stable aspect ratios for heatmaps, grids, timelines, and schematics.

## Data Hygiene Before Plotting

Check the data table before visual design:

- Remove blank records and unintended missing categories.
- Preserve true zero values.
- Set factor order deliberately.
- Check missingness, batch labels, duplicate rows, and inconsistent identifiers.
- Confirm units and transformations.
- Confirm denominator definitions for percentages and rates.
- Match plotted values to source tables after aggregation.
- Keep source data in a reproducible location and avoid manual spreadsheet edits for final figures.

## Schematics and Model Figures

Mechanistic or conceptual schematics must separate evidence levels:

- Use solid lines for observed or directly supported relationships.
- Use dashed lines for candidate, inferred, or hypothesized relationships.
- Use labels such as observed, associated, candidate, inferred, or proposed when needed.
- Do not imply molecular or causal direction if the data only support correlation.
- Keep icons and illustrations subordinate to the scientific relation.
- Prefer vector-editable outputs for final model figures.

For AI-generated diagrams, use them as drafts or visual aids unless all labels, arrows, and relationships can be verified and edited reproducibly.

## Export and Reproducibility

Final figure production should leave an audit trail:

- Source data table or serialized plotting input.
- Plotting script or notebook.
- Exported PDF/SVG for vector art when possible.
- Exported PNG/TIFF at journal-required resolution for raster or preview.
- Figure legend with sample size, statistics, abbreviations, and data source boundaries.
- Manifest or notes linking figure panels to scripts and input tables for complex papers.

Recommended export checks:

- PDF/SVG for line art and text-heavy plots.
- 300 dpi or higher for raster previews; follow journal rules for final TIFF/PNG.
- Embed or use standard fonts where possible.
- Open the exported file directly and inspect it at final size.

## Final QC Checklist

Before calling a figure ready, confirm:

- The figure brief is complete.
- The panel supports the exact Results claim.
- The chart type matches the data question.
- Sample sizes, uncertainty, tests, and corrections are shown or stated.
- No unintended `NA` category is visible.
- Factor order is biologically or analytically meaningful.
- Text is readable at final width.
- Labels do not overlap data or other labels.
- Legends match the plotted values and colors.
- Color remains interpretable for colorblind readers and in grayscale when needed.
- Axis limits and transformations do not exaggerate the result.
- Main vs supplementary placement is justified.
- Source data, script, and output path are traceable.
