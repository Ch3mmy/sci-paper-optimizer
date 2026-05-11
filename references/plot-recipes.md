# Plot Recipes

Use this reference when converting real analysis tables into publication-style
figures. These recipes assume R/ggplot2 and the reusable theme script:

```r
source("scripts/sci_plot_theme.R")
```

Treat the code as a starting point. Always set factor order, sample definitions,
units, and statistical annotations from the manuscript's actual evidence table.

## Plot Decision Guide

| Data question | Preferred recipe | Avoid |
| --- | --- | --- |
| Small group comparison | Raw points + mean/CI, boxplot, or violin | Bar-only mean plot |
| Many ranked categories | Horizontal bar or dot plot ordered by effect | Alphabetical order |
| Ordered stage/time/dose | Line or point-range plot with intervals | Unordered bars |
| Differential omics | Volcano, MA, heatmap, coefficient plot | P-value-only display |
| Enrichment/pathway | Dot plot or forest plot with FDR and effect | Count-only bar chart |
| Multi-species/context | `facet_grid()` with stable colors | Recolored independent panels |
| Methylation/DMR | Context facets, DMR volcano, metaplot, tracks | Mixed CG/CHG/CHH colors |
| Model associations | Coefficient/forest plot with CI and null line | Stars without intervals |
| Category transitions | Alluvial only for few readable flows | Dense crossing Sankey |
| Locus or genome evidence | Genome track, Manhattan, synteny schematic | Decorative chromosome art |

## Shared Preparation

```r
library(ggplot2)
library(scales)
source("scripts/sci_plot_theme.R")

df$group <- factor(df$group, levels = c("Control", "Treatment"))
df$stage <- factor(df$stage, levels = paste0("S", 1:5))
df <- subset(df, !is.na(group) & group != "")
```

## Group Summary With Raw Points

Use for small experimental groups when the independent replicate is visible.

```r
sum_df <- aggregate(value ~ group, df, function(x) {
  c(mean = mean(x), ci = qt(0.975, length(x) - 1) * sd(x) / sqrt(length(x)))
})
sum_df <- data.frame(group = sum_df$group,
                     mean = sum_df$value[, "mean"],
                     ci = sum_df$value[, "ci"])

p <- ggplot(sum_df, aes(group, mean, fill = group)) +
  geom_col(width = 0.62, color = "grey25", linewidth = 0.18) +
  geom_errorbar(aes(ymin = mean - ci, ymax = mean + ci),
                width = 0.14, linewidth = 0.35) +
  geom_jitter(data = df, aes(group, value), inherit.aes = FALSE,
              width = 0.06, size = 0.8, color = "grey25") +
  labs(x = NULL, y = "Response") +
  theme_sci(base_size = 7) +
  theme(legend.position = "none")
```

## Boxplot With Compact Letters

Use for multiple groups after a documented post hoc test.

```r
p <- ggplot(df, aes(group, value, fill = group)) +
  geom_boxplot(width = 0.56, outlier.shape = NA,
               color = "grey20", linewidth = 0.30) +
  geom_jitter(width = 0.08, size = 0.55, color = "grey30") +
  geom_text(data = letters_df, aes(group, y, label = letter),
            inherit.aes = FALSE, size = 2.4, fontface = "bold") +
  labs(x = NULL, y = "Signal") +
  theme_sci(base_size = 7) +
  theme(legend.position = "none")
```

Legend requirement: state the model/test, correction, and the rule for letters.

## Violin With Inner Summary

Use only when each group has enough observations to estimate distribution shape.

```r
p <- ggplot(df, aes(group, value, fill = group)) +
  geom_violin(width = 0.85, trim = TRUE, color = "grey20", linewidth = 0.28) +
  geom_boxplot(width = 0.12, outlier.shape = NA,
               fill = neutral_mid_color, color = "grey20", linewidth = 0.22) +
  labs(x = NULL, y = "Module score") +
  theme_sci(base_size = 7) +
  theme(legend.position = "none")
```

## Ordered Stage Or Time-Course

Use for ordered biology: development, dose, time, environmental gradient.

```r
p <- ggplot(summary_df, aes(stage, mean, group = treatment, color = treatment)) +
  geom_errorbar(aes(ymin = mean - ci, ymax = mean + ci),
                width = 0.10, linewidth = 0.30) +
  geom_line(linewidth = 0.55) +
  geom_point(size = 1.1) +
  labs(x = "Stage", y = "Response", color = NULL) +
  theme_sci(base_size = 7, grid = TRUE)
```

Do not use this for unordered categories.

## Heatmap With Stable Scale

Use for expression, methylation, correlation, evidence matrices, or candidate
status summaries. Set row and column order deliberately before plotting.

```r
p <- ggplot(mat_long, aes(sample, feature, fill = z)) +
  geom_tile(color = tile_border_color, linewidth = 0.12) +
  scale_fill_z(name = "z score") +
  labs(x = NULL, y = NULL) +
  theme_sci_heatmap(base_size = 6.5)
```

Use `missing_value_color` for missing values. Do not use white as a data class.

## Volcano Plot

Use for differential expression, methylation, proteomics, and screens.

```r
res$status <- ifelse(res$FDR < 0.05 & res$log2FC > 1, "Up",
                     ifelse(res$FDR < 0.05 & res$log2FC < -1, "Down", "NS"))

p <- ggplot(res, aes(log2FC, -log10(FDR), color = status)) +
  geom_point(size = 0.55) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed",
             linewidth = 0.25, color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed",
             linewidth = 0.25, color = "grey40") +
  scale_color_effect(name = NULL) +
  labs(x = expression(log[2]("fold change")), y = expression(-log[10]("FDR"))) +
  theme_sci(base_size = 7)
```

For DMRs, replace `log2FC` with `delta_methylation` and use `scale_color_dmr()`.

## MA Plot

Use to show effect size across abundance/expression level.

```r
p <- ggplot(res, aes(log10(base_mean), log2FC, color = status)) +
  geom_hline(yintercept = 0, color = "grey75", linewidth = 0.25) +
  geom_hline(yintercept = c(-1, 1), linetype = "dashed",
             color = "grey40", linewidth = 0.22) +
  geom_point(size = 0.55) +
  scale_color_effect(name = NULL) +
  labs(x = expression(log[10]("mean expression")),
       y = expression(log[2]("fold change"))) +
  theme_sci(base_size = 7)
```

## Enrichment Dot Plot

Use for GO, KEGG, pathway, motif, or gene-set enrichment. Encode effect and
evidence separately: x = gene ratio or odds ratio, size = count, color = FDR.

```r
enrich$term <- factor(enrich$term, levels = enrich$term[order(enrich$gene_ratio)])

p <- ggplot(enrich, aes(gene_ratio, term,
                        size = gene_count, color = -log10(FDR))) +
  geom_point() +
  scale_color_fdr() +
  scale_size_continuous(range = c(1.8, 4.6), name = "Genes") +
  labs(x = "Gene ratio", y = NULL) +
  theme_sci(base_size = 7)
```

Do not use color for both category and FDR in the same dot unless the panel has a
separate, clearly labelled annotation strip.

## Coefficient Or Forest Plot

Use for model estimates, odds ratios, effect sizes, and associations.

```r
p <- ggplot(coef_df, aes(estimate, term, color = group)) +
  geom_vline(xintercept = 0, linetype = "dashed",
             linewidth = 0.30, color = "grey45") +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high),
                orientation = "y", width = 0.14, linewidth = 0.45) +
  geom_point(size = 1.5) +
  labs(x = "Effect (95% CI)", y = NULL, color = NULL) +
  theme_sci(base_size = 7)
```

For ratios, put the null line at 1 and use a log-scaled x-axis if appropriate.

## PCA Or Sample Scatter

Use for sample structure and QC. Avoid mechanistic claims from unsupervised
separation alone.

```r
p <- ggplot(pca_df, aes(PC1, PC2, color = species, shape = batch)) +
  geom_point(size = 1.8) +
  scale_color_species(name = "Species") +
  labs(x = "PC1 (32%)", y = "PC2 (18%)", shape = "Batch") +
  theme_sci(base_size = 7)
```

## Faceted Multi-Species Or Multi-Context Plot

Use when the same statistic is compared across species and assay contexts.

```r
p <- ggplot(methylation, aes(stage, mC, group = 1, color = context)) +
  geom_errorbar(aes(ymin = mC - ci, ymax = mC + ci), width = 0.10,
                linewidth = 0.25) +
  geom_line(linewidth = 0.45) +
  geom_point(size = 1.0) +
  facet_grid(species ~ context, labeller = labeller(species = species_facet_labeller())) +
  scale_color_context(name = "Context") +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Stage", y = "mC level") +
  theme_sci_facet(base_size = 6.2)
```

Keep axes shared when magnitudes are compared. Use `CG`, `CHG`, `CHH` order for
methylation unless a specific biological question requires otherwise.

## DMR Volcano By Context

```r
dmr$status <- ifelse(dmr$FDR < 0.05 & dmr$delta_mC > 0.12, "Hyper",
                     ifelse(dmr$FDR < 0.05 & dmr$delta_mC < -0.12, "Hypo", "Stable"))

p <- ggplot(dmr, aes(delta_mC, -log10(FDR), color = status)) +
  geom_point(size = 0.5) +
  geom_vline(xintercept = c(-0.12, 0.12), linetype = "dashed",
             linewidth = 0.22, color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed",
             linewidth = 0.22, color = "grey40") +
  facet_wrap(~ context, nrow = 1) +
  scale_color_dmr(name = NULL) +
  labs(x = expression(Delta*" methylation"), y = expression(-log[10]("FDR"))) +
  theme_sci_facet(base_size = 6.3)
```

## Epigenomic Track

Use for compact locus-level methylation, TE, sRNA, DMR, or gene annotation.

```r
p <- ggplot(signal_df, aes(position_kb, value, color = context)) +
  geom_rect(data = tracks,
            aes(xmin = start_kb, xmax = end_kb, ymin = ymin, ymax = ymax,
                fill = feature),
            inherit.aes = FALSE, color = "grey25", linewidth = 0.12) +
  geom_line(linewidth = 0.45) +
  facet_wrap(~ species, ncol = 1, labeller = labeller(species = species_facet_labeller())) +
  scale_color_context(name = "Context") +
  scale_fill_manual(values = epigenome_track_palette, name = "Track") +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Position (kb)", y = "mC") +
  theme_sci(base_size = 6.3)
```

## Manhattan Plot

```r
p <- ggplot(gwas, aes(genome_pos, -log10(P), color = chr_parity)) +
  geom_point(size = 0.45) +
  geom_point(data = subset(gwas, P < genome_threshold),
             aes(genome_pos, -log10(P)), inherit.aes = FALSE,
             color = "#E64B35", size = 0.75) +
  geom_hline(yintercept = -log10(genome_threshold), linetype = "dashed",
             linewidth = 0.25, color = "grey40") +
  scale_color_manual(values = c(odd = "#3C5488", even = "#9A9A9A"), guide = "none") +
  labs(x = "Chromosome", y = expression(-log[10]("P"))) +
  theme_sci(base_size = 7)
```

## Protein Domain And Lollipop

```r
p <- ggplot() +
  geom_segment(aes(x = 1, xend = protein_length, y = 1, yend = 1),
               color = "grey25", linewidth = 0.7) +
  geom_rect(data = domains,
            aes(xmin = start, xmax = end, ymin = 0.86, ymax = 1.14, fill = domain),
            color = "grey25", linewidth = 0.15) +
  geom_segment(data = sites,
               aes(x = pos, xend = pos, y = 1.15, yend = 1.15 + score, color = type),
               linewidth = 0.30) +
  geom_point(data = sites,
             aes(x = pos, y = 1.15 + score, color = type), size = 1.4) +
  scale_y_continuous(NULL, breaks = NULL) +
  labs(x = "Protein coordinate (aa)", fill = NULL, color = NULL) +
  theme_sci(base_size = 7) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())
```

## Category Transition Or Alluvial-Like Summary

Use only for a small number of classes and stages. State denominators in the
legend or source table.

```r
p <- ggplot(flow_df, aes(x = stage, stratum = state, alluvium = id,
                         y = count, fill = state)) +
  geom_flow(color = "grey85", linewidth = 0.12) +
  geom_stratum(width = 0.18, color = "grey25", linewidth = 0.15) +
  labs(x = NULL, y = "Count", fill = NULL) +
  theme_sci(base_size = 7)
```

If `ggalluvial` is unavailable or the paths are too dense, use stacked
proportions or a transition matrix instead.

## Export

```r
sci_save_plot(p, "figures/Fig1A.svg", layout = "single", aspect = 0.72)
sci_save_plot(p, "figures/Fig1.pdf", layout = "double", height = 4.8)
```

Inspect exported files at the final journal width before calling them ready.
