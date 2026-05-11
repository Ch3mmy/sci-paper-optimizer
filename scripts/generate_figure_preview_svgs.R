#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
  library(scales)
})

`%||%` <- function(x, y) if (length(x) == 0 || is.na(x)) y else x

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args_all[grep("^--file=", args_all)][1])
script_dir <- dirname(normalizePath(file_arg %||% getwd()))
skill_root <- dirname(script_dir)
out_dir <- file.path(skill_root, "assets", "figure_previews")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

save_svg <- function(name, width = 7.1, height = 4.8, draw_fun) {
  path <- file.path(out_dir, paste0(name, ".svg"))
  pdf_path <- tempfile(pattern = paste0(name, "_"), fileext = ".pdf")
  pdf(pdf_path, width = width, height = height, bg = "white", pointsize = 8, useDingbats = FALSE)
  draw_fun()
  dev.off()
  status <- system2("pdftocairo", c("-svg", pdf_path, path))
  unlink(pdf_path)
  if (!identical(status, 0L) || !file.exists(path) || file.info(path)$size == 0) {
    stop("Failed to convert preview PDF to SVG: ", path)
  }
  message("Wrote ", path)
}

pal_npg <- c(
  red = "#E64B35", cyan = "#4DBBD5", teal = "#00A087", navy = "#3C5488",
  salmon = "#F39B7F", lavender = "#8491B4", mint = "#91D1C2",
  crimson = "#DC0000", brown = "#7E6148", sand = "#B09C85"
)

pal_aaas <- c(
  blue = "#3B4992", orange = "#EE0000", green = "#008B45", purple = "#631879",
  ochre = "#BB0021", cyan = "#008280", gray = "#808180"
)

context_cols <- c(CG = "#E64B35", CHG = "#4DBBD5", CHH = "#00A087")
dmr_cols <- c(Hyper = "#E64B35", Hypo = "#3C5488", Stable = "#9A9A9A")
epigenome_cols <- c(TE = "#7E6148", `24-nt siRNA` = "#00A087", RdDM = "#8491B4", Gene = "#3C5488")
neutral_mid <- "#E6E6E6"
tile_border <- "#F0F0F0"

scale_color_fdr <- function(name = expression(-log[10]("FDR"))) {
  scale_color_gradientn(
    colors = c("#3C5488", "#4DBBD5", "#00A087", "#F39B7F", "#E64B35"),
    name = name
  )
}

standard_enrichment_dot <- function(dat, title = "Enrichment dot plot") {
  dat$term <- factor(dat$term, levels = dat$term[order(dat$ratio, decreasing = FALSE)])
  dat$neglog10_fdr <- -log10(dat$fdr)
  ggplot(dat, aes(ratio, term, size = count, color = neglog10_fdr)) +
    geom_point() +
    scale_color_fdr() +
    scale_size_continuous(range = c(1.8, 4.6), breaks = c(20, 30, 40), name = "Genes") +
    scale_x_continuous(expand = expansion(mult = c(0.02, 0.10))) +
    labs(title = title, x = "Gene ratio", y = NULL) +
    pub_theme(6.3, FALSE) +
    theme(legend.position = "right")
}

pub_theme <- function(base_size = 7, grid = FALSE) {
  base <- if (grid) theme_minimal(base_size = base_size) else theme_classic(base_size = base_size)
  base +
    theme(
      text = element_text(color = "#222222"),
      axis.title = element_text(size = base_size),
      axis.text = element_text(size = base_size - 0.4, color = "#222222"),
      axis.line = element_line(linewidth = 0.30, color = "#222222"),
      axis.ticks = element_line(linewidth = 0.25, color = "#222222"),
      axis.ticks.length = unit(1.1, "mm"),
      panel.grid.major = if (grid) element_line(linewidth = 0.20, color = "#E7E7E7") else element_blank(),
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = base_size + 0.4, face = "bold", hjust = 0),
      legend.title = element_text(size = base_size - 0.2),
      legend.text = element_text(size = base_size - 0.5),
      legend.key.size = unit(2.7, "mm"),
      legend.background = element_blank(),
      strip.background = element_blank(),
      strip.text = element_text(size = base_size, face = "bold"),
      plot.margin = margin(3, 4, 3, 3, "pt")
    )
}

draw_plot <- function(plot, x, y, w, h, label = NULL) {
  print(plot, vp = viewport(x = unit(x, "npc"), y = unit(y, "npc"), width = unit(w, "npc"), height = unit(h, "npc")))
  if (!is.null(label)) {
    grid.text(label, x = unit(x - w / 2 - 0.012, "npc"), y = unit(y + h / 2 + 0.018, "npc"),
              just = c("left", "top"), gp = gpar(fontsize = 12, fontface = "bold", col = "#222222"))
  }
}

palettes <- list(
  evidence = list(name = "Evidence minimal", control = "#7A7A7A", stress = "#0072B2", accent = "#D55E00",
                  low = "#2166AC", mid = neutral_mid, high = "#B2182B", cat = c("#0072B2", "#D55E00", "#009E73", "#CC79A7")),
  plant = list(name = "Plant natural", control = "#2E7D32", stress = "#2A9D8F", accent = "#C9A227",
               low = "#3A6EA5", mid = neutral_mid, high = "#B45F4D", cat = c("#2E7D32", "#2A9D8F", "#3A6EA5", "#C9A227")),
  omics = list(name = "Omics compact", control = "#2166AC", stress = "#B2182B", accent = "#E69F00",
               low = "#2166AC", mid = neutral_mid, high = "#B2182B", cat = c("#2166AC", "#67A9CF", "#B2182B", "#F4A582")),
  mechanism = list(name = "Mechanism clean", control = "#2F3A45", stress = "#F2B701", accent = "#59A14F",
                   low = "#4C78A8", mid = neutral_mid, high = "#E45756", cat = c("#2F3A45", "#4C78A8", "#59A14F", "#F2B701"))
)

set.seed(19)

stage_df <- expand.grid(stage = 1:5, treatment = c("Control", "Stress"), KEEP.OUT.ATTRS = FALSE)
stage_df$mean <- ifelse(stage_df$treatment == "Control",
                        1.1 + 0.18 * stage_df$stage + sin(stage_df$stage / 1.4) * 0.09,
                        0.95 + 0.38 * stage_df$stage + sin(stage_df$stage / 1.5) * 0.12)
stage_df$se <- ifelse(stage_df$treatment == "Control", 0.10, 0.14)
stage_raw <- do.call(rbind, lapply(seq_len(nrow(stage_df)), function(i) {
  data.frame(stage = stage_df$stage[i], treatment = stage_df$treatment[i],
             value = rnorm(6, stage_df$mean[i], stage_df$se[i] * 1.7))
}))

heat_df <- expand.grid(gene = paste0("G", sprintf("%02d", 1:12)),
                       sample = paste0(rep(c("C", "S"), each = 4), 1:4),
                       KEEP.OUT.ATTRS = FALSE)
heat_df$gene <- factor(heat_df$gene, levels = rev(unique(heat_df$gene)))
heat_df$sample <- factor(heat_df$sample, levels = unique(heat_df$sample))
heat_df$value <- sin(as.numeric(heat_df$gene) / 2.2) + cos(as.numeric(heat_df$sample) / 2.1) + rnorm(nrow(heat_df), sd = 0.22)
heat_df$bin <- cut(heat_df$value, breaks = c(-Inf, -1.0, -0.35, 0.35, 1.0, Inf),
                   labels = c("low", "mild low", "mid", "mild high", "high"))

effect_df <- data.frame(
  module = factor(c("Hormone", "Cell wall", "TE/RdDM", "Stress", "Metabolism"), levels = rev(c("Hormone", "Cell wall", "TE/RdDM", "Stress", "Metabolism"))),
  estimate = c(0.62, 0.35, -0.42, 0.78, 0.18),
  lo = c(0.28, 0.08, -0.76, 0.41, -0.08),
  hi = c(0.95, 0.61, -0.13, 1.12, 0.43)
)

enrich_df <- data.frame(
  term = factor(c("ABA response", "Cell cycle", "DNA repair", "Cell wall", "Photosynthesis"), levels = rev(c("ABA response", "Cell cycle", "DNA repair", "Cell wall", "Photosynthesis"))),
  ratio = c(0.34, 0.25, 0.22, 0.17, 0.13),
  fdr = c(2e-5, 4e-4, 0.002, 0.012, 0.043),
  count = c(45, 33, 28, 21, 17)
)
enrich_df$evidence <- factor(c("very high", "high", "medium", "low", "low"),
                             levels = c("low", "medium", "high", "very high"))

make_theme_plots <- function(pal) {
  line <- ggplot(stage_df, aes(stage, mean, color = treatment, fill = treatment)) +
    geom_errorbar(aes(ymin = mean - 1.96 * se, ymax = mean + 1.96 * se), width = 0.08, linewidth = 0.28) +
    geom_point(data = stage_raw, aes(stage, value), inherit.aes = FALSE, color = "#9A9A9A", size = 0.55,
               position = position_jitter(width = 0.045, height = 0)) +
    geom_line(linewidth = 0.48) +
    geom_point(size = 1.35) +
    scale_x_continuous(breaks = 1:5, labels = paste0("S", 1:5)) +
    scale_color_manual(values = c(Control = pal$control, Stress = pal$stress)) +
    scale_fill_manual(values = c(Control = pal$control, Stress = pal$stress)) +
    coord_cartesian(ylim = c(0.75, 3.05), clip = "off") +
    labs(title = "Development trajectory", x = "Stage", y = "Response", color = NULL, fill = NULL) +
    pub_theme(6.4, TRUE) +
    theme(legend.position = c(0.04, 0.96), legend.justification = c(0, 1))

  heat_cols <- c("low" = pal$low, "mild low" = pal$cat[[1]], "mid" = pal$mid, "mild high" = pal$cat[[3]], "high" = pal$high)
  heat <- ggplot(heat_df, aes(sample, gene, fill = bin)) +
    geom_tile(color = tile_border, linewidth = 0.12) +
    scale_fill_manual(values = heat_cols, name = "z bin") +
    labs(title = "Expression module", x = NULL, y = NULL) +
    pub_theme(6.1, FALSE) +
    theme(axis.ticks = element_blank(), axis.line = element_blank(), legend.position = "right")

  forest <- ggplot(effect_df, aes(estimate, module)) +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.25, color = "#666666") +
    geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.12, linewidth = 0.45, color = pal$stress) +
    geom_point(size = 1.7, color = pal$accent) +
    labs(title = "Model contrasts", x = "Effect (95% CI)", y = NULL) +
    pub_theme(6.3, FALSE)

  dot <- standard_enrichment_dot(enrich_df, "Functional enrichment")

  list(line = line, heat = heat, forest = forest, dot = dot)
}

draw_four_panel_theme <- function(key, pal) {
  plots <- make_theme_plots(pal)
  save_svg(paste0("theme_system_", key), 7.1, 4.8, function() {
    grid.newpage()
    grid.rect(gp = gpar(fill = "white", col = NA))
    grid.text(pal$name, x = unit(0.03, "npc"), y = unit(0.97, "npc"), just = c("left", "top"),
              gp = gpar(fontsize = 12, fontface = "bold", col = "#222222"))
    draw_plot(plots$line, 0.27, 0.70, 0.42, 0.38, "A")
    draw_plot(plots$heat, 0.75, 0.70, 0.42, 0.38, "B")
    draw_plot(plots$forest, 0.27, 0.25, 0.42, 0.38, "C")
    draw_plot(plots$dot, 0.75, 0.25, 0.42, 0.38, "D")
  })
}

for (nm in names(palettes)) draw_four_panel_theme(nm, palettes[[nm]])

save_svg("palette_reference", 7.1, 3.4, function() {
  grid.newpage()
  grid.rect(gp = gpar(fill = "white", col = NA))
  rows <- list(
    "CNS-inspired categorical" = unname(pal_npg[1:8]),
    "Colorblind categorical" = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9", "#F0E442", "#7A7A7A"),
    "Plant ecology" = c("#2E7D32", "#2A9D8F", "#3A6EA5", "#C9A227", "#B45F4D", "#6E6E6E", "#A3B18A", "#D9CBA3"),
    "Genomics tracks" = c("#1B4F72", "#2874A6", "#48A868", "#D68910", "#A93226", "#7D3C98", "#BDBDBD", "#E6E6E6"),
    "Transcriptome DE" = c("#2166AC", "#67A9CF", "#D9D9D9", "#F4A582", "#B2182B", "#404040", "#E6E6E6", "#BDBDBD"),
    "Proteomics/PTM" = c("#355C7D", "#6C5B7B", "#C06C84", "#F67280", "#F8B195", "#99B898", "#2A9D8F", "#CFCFCF")
  )
  grid.text("Publication palette references", x = unit(0.04, "npc"), y = unit(0.92, "npc"), just = "left",
            gp = gpar(fontsize = 13, fontface = "bold", col = "#222222"))
  grid.text("Pick one primary family per manuscript; reserve accents for contrasts, thresholds, and highlights.",
            x = unit(0.04, "npc"), y = unit(0.83, "npc"), just = "left",
            gp = gpar(fontsize = 8, col = "#555555"))
  yvals <- seq(0.66, 0.18, length.out = length(rows))
  for (i in seq_along(rows)) {
    grid.text(names(rows)[i], x = unit(0.05, "npc"), y = unit(yvals[i], "npc"), just = "left",
              gp = gpar(fontsize = 8, fontface = "bold", col = "#222222"))
    cols <- rows[[i]]
    for (j in seq_along(cols)) {
      grid.rect(x = unit(0.34 + (j - 1) * 0.065, "npc"), y = unit(yvals[i], "npc"),
                width = unit(0.047, "npc"), height = unit(0.058, "npc"),
                gp = gpar(fill = cols[j], col = "#DDDDDD", lwd = 0.25))
    }
  }
})

raw_bar <- do.call(rbind, lapply(c("WT", "mut1", "mut2"), function(g) {
  data.frame(group = g, value = rnorm(8, c(WT = 1.0, mut1 = 1.55, mut2 = 0.78)[g], 0.18))
}))
raw_bar$group <- factor(raw_bar$group, levels = c("WT", "mut1", "mut2"))
bar_sum <- aggregate(value ~ group, raw_bar, function(x) c(mean = mean(x), se = sd(x) / sqrt(length(x))))
bar_sum <- data.frame(group = bar_sum$group, mean = bar_sum$value[, "mean"], se = bar_sum$value[, "se"])
bar_sum$group <- factor(bar_sum$group, levels = c("WT", "mut1", "mut2"))

box_df <- do.call(rbind, lapply(c("Root", "Stem", "Leaf", "Seed"), function(tissue) {
  data.frame(tissue = tissue, value = rnorm(18, c(Root = 3.0, Stem = 3.6, Leaf = 4.4, Seed = 2.6)[tissue], 0.42))
}))
box_df$tissue <- factor(box_df$tissue, levels = c("Root", "Stem", "Leaf", "Seed"))
letters_df <- data.frame(tissue = factor(c("Root", "Stem", "Leaf", "Seed"), levels = c("Root", "Stem", "Leaf", "Seed")),
                         y = c(4.0, 4.55, 5.12, 3.55), label = c("b", "ab", "a", "c"))
vio_df <- do.call(rbind, lapply(c("Cluster 1", "Cluster 2", "Cluster 3"), function(cl) {
  data.frame(cluster = cl, score = c(rnorm(70, c("Cluster 1" = 0.25, "Cluster 2" = 0.95, "Cluster 3" = 1.35)[cl], 0.25),
                                     rnorm(20, c("Cluster 1" = 0.70, "Cluster 2" = 1.30, "Cluster 3" = 1.72)[cl], 0.20)))
}))
vio_df$cluster <- factor(vio_df$cluster, levels = c("Cluster 1", "Cluster 2", "Cluster 3"))

make_quant_plots <- function() {
  bar <- ggplot(bar_sum, aes(group, mean, fill = group)) +
    geom_col(width = 0.62, color = "#333333", linewidth = 0.18) +
    geom_errorbar(aes(ymin = mean - 1.96 * se, ymax = mean + 1.96 * se), width = 0.14, linewidth = 0.35) +
    geom_jitter(data = raw_bar, aes(group, value), inherit.aes = FALSE, width = 0.06, size = 0.75, color = "#4D4D4D") +
    annotate("segment", x = 1, xend = 2, y = 2.03, yend = 2.03, linewidth = 0.28) +
    annotate("segment", x = 1, xend = 1, y = 1.98, yend = 2.03, linewidth = 0.28) +
    annotate("segment", x = 2, xend = 2, y = 1.98, yend = 2.03, linewidth = 0.28) +
    annotate("text", x = 1.5, y = 2.12, label = "Holm adj. P = 0.018", size = 2.15) +
    scale_fill_manual(values = c(WT = "#7A7A7A", mut1 = pal_npg[["cyan"]], mut2 = pal_npg[["red"]])) +
    coord_cartesian(ylim = c(0, 2.25), clip = "off") +
    labs(title = "Replicate summary", x = NULL, y = "Relative expression") +
    pub_theme(6.5, FALSE) +
    theme(legend.position = "none")

  box <- ggplot(box_df, aes(tissue, value, fill = tissue)) +
    geom_boxplot(width = 0.56, outlier.shape = NA, color = "#333333", linewidth = 0.30) +
    geom_jitter(width = 0.08, size = 0.58, color = "#5A5A5A") +
    geom_text(data = letters_df, aes(tissue, y, label = label), inherit.aes = FALSE, size = 2.5, fontface = "bold") +
    scale_fill_manual(values = c(Root = pal_npg[["teal"]], Stem = pal_npg[["cyan"]], Leaf = pal_npg[["navy"]], Seed = pal_npg[["sand"]])) +
    coord_cartesian(ylim = c(1.6, 5.35), clip = "off") +
    labs(title = "Post hoc letters", x = NULL, y = "Metabolite level") +
    pub_theme(6.5, FALSE) +
    theme(legend.position = "none")

  violin <- ggplot(vio_df, aes(cluster, score, fill = cluster)) +
    geom_violin(width = 0.82, color = "#333333", linewidth = 0.28, trim = TRUE) +
    geom_boxplot(width = 0.13, outlier.shape = NA, color = "#333333", fill = neutral_mid, linewidth = 0.23) +
    annotate("text", x = 2, y = max(vio_df$score) + 0.18, label = "Kruskal-Wallis FDR = 0.006", size = 2.1) +
    scale_fill_manual(values = c("Cluster 1" = "#7A7A7A", "Cluster 2" = pal_npg[["cyan"]], "Cluster 3" = pal_npg[["red"]])) +
    coord_cartesian(ylim = c(min(vio_df$score) - 0.12, max(vio_df$score) + 0.36), clip = "off") +
    labs(title = "Distribution shape", x = NULL, y = "Module score") +
    pub_theme(6.5, FALSE) +
    theme(legend.position = "none")

  line <- ggplot(stage_df, aes(stage, mean, color = treatment, fill = treatment)) +
    geom_errorbar(aes(ymin = mean - 1.96 * se, ymax = mean + 1.96 * se), width = 0.08, linewidth = 0.28) +
    geom_line(linewidth = 0.46) +
    geom_point(size = 1.2) +
    scale_x_continuous(breaks = 1:5, labels = paste0("S", 1:5)) +
    scale_color_manual(values = c(Control = "#7A7A7A", Stress = "#0072B2")) +
    scale_fill_manual(values = c(Control = "#7A7A7A", Stress = "#0072B2")) +
    labs(title = "Ordered trajectory", x = "Stage", y = "Signal", color = NULL, fill = NULL) +
    pub_theme(6.5, TRUE) +
    theme(legend.position = c(0.05, 0.95), legend.justification = c(0, 1))
  list(bar = bar, box = box, violin = violin, line = line)
}

save_svg("biology_quantitative", 7.1, 4.8, function() {
  plots <- make_quant_plots()
  grid.newpage()
  grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(plots$bar, 0.27, 0.70, 0.42, 0.38, "A")
  draw_plot(plots$box, 0.75, 0.70, 0.42, 0.38, "B")
  draw_plot(plots$violin, 0.27, 0.25, 0.42, 0.38, "C")
  draw_plot(plots$line, 0.75, 0.25, 0.42, 0.38, "D")
})

chr_lengths <- c(Chr1 = 32, Chr2 = 28, Chr3 = 36, Chr4 = 24, Chr5 = 30)
man <- do.call(rbind, lapply(seq_along(chr_lengths), function(i) {
  data.frame(chr = names(chr_lengths)[i], pos = sort(runif(120, 0, chr_lengths[i])), p = runif(120, 0.01, 1))
}))
man$p[sample(seq_len(nrow(man)), 16)] <- 10 ^ runif(16, -8, -5.2)
offset <- cumsum(c(0, head(chr_lengths, -1))); names(offset) <- names(chr_lengths)
man$x <- man$pos + offset[man$chr]
man$neglog10 <- -log10(man$p)
man$chr_index <- as.numeric(factor(man$chr, levels = names(chr_lengths)))
man$hit <- man$p < 5e-6
centers <- offset + chr_lengths / 2

features <- data.frame(track = c(rep("Genes", 8), rep("TE density", 8), rep("DMRs", 6)),
                       start = c(4, 10, 18, 27, 38, 49, 62, 76, 3, 14, 24, 35, 51, 64, 72, 84, 8, 31, 46, 58, 70, 88),
                       end = c(8, 15, 23, 33, 44, 54, 68, 81, 10, 20, 30, 43, 58, 69, 79, 92, 12, 35, 49, 62, 74, 92),
                       class = c(rep("Gene", 8), rep(c("Low", "High"), 4), rep(c("Hyper", "Hypo"), 3)))
features$track <- factor(features$track, levels = c("DMRs", "TE density", "Genes"))

save_svg("biology_genomics", 7.1, 4.8, function() {
  manhattan <- ggplot(man, aes(x, neglog10, color = chr_index %% 2 == 0)) +
    geom_point(size = 0.42) +
    geom_point(data = man[man$hit, ], aes(x, neglog10), inherit.aes = FALSE, color = pal_npg[["red"]], size = 0.78) +
    geom_hline(yintercept = -log10(5e-6), linetype = "dashed", linewidth = 0.25, color = "#555555") +
    scale_x_continuous(breaks = centers, labels = names(chr_lengths), expand = expansion(mult = c(0.01, 0.02))) +
    scale_color_manual(values = c("FALSE" = pal_npg[["navy"]], "TRUE" = "#9A9A9A")) +
    labs(title = "Chromosome-wide signal", x = "Chromosome", y = expression(-log[10]("P"))) +
    pub_theme(6.4, FALSE) +
    theme(legend.position = "none")

  tracks <- ggplot(features) +
    geom_segment(aes(x = 0, xend = 96, y = track, yend = track), color = "#D5D5D5", linewidth = 1.4, lineend = "round") +
    geom_segment(aes(x = start, xend = end, y = track, yend = track, color = class), linewidth = 3.6, lineend = "butt") +
    scale_color_manual(values = c(Gene = pal_npg[["navy"]], Low = "#91D1C2", High = "#F39B7F", Hyper = pal_npg[["red"]], Hypo = pal_npg[["cyan"]])) +
    labs(title = "Feature tracks", x = "Position (Mb)", y = NULL, color = NULL) +
    pub_theme(6.3, FALSE) +
    theme(legend.position = "bottom")

  grid.newpage()
  grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(manhattan, 0.50, 0.73, 0.88, 0.34, "A")
  draw_plot(tracks, 0.27, 0.27, 0.42, 0.36, "B")
  draw_synteny <- function() {
    grid.rect(gp = gpar(fill = "white", col = NA))
    grid.text("Synteny blocks", x = unit(0.03, "npc"), y = unit(0.95, "npc"), just = "left",
              gp = gpar(fontsize = 8, fontface = "bold"))
    top_y <- 0.66; bot_y <- 0.30
    grid.lines(unit(c(0.13, 0.90), "npc"), unit(c(top_y, top_y), "npc"), gp = gpar(col = "#2F3A45", lwd = 5, lineend = "round"))
    grid.lines(unit(c(0.13, 0.90), "npc"), unit(c(bot_y, bot_y), "npc"), gp = gpar(col = "#2F3A45", lwd = 5, lineend = "round"))
    grid.text("Sp A", x = unit(0.10, "npc"), y = unit(top_y, "npc"), just = "right", gp = gpar(fontsize = 6.5, fontface = "bold"))
    grid.text("Sp B", x = unit(0.10, "npc"), y = unit(bot_y, "npc"), just = "right", gp = gpar(fontsize = 6.5, fontface = "bold"))
    cols <- c("#4C78A8", "#59A14F", "#F2B701", "#E45756", "#8E6C8A")
    pale_cols <- c("#D9E6F2", "#DDEED9", "#F8E9B5", "#F4D0CF", "#E9DCEA")
    top <- matrix(c(0.16, 0.27, 0.31, 0.43, 0.48, 0.60, 0.64, 0.74, 0.78, 0.86), ncol = 2, byrow = TRUE)
    bot <- matrix(c(0.18, 0.29, 0.34, 0.46, 0.63, 0.73, 0.50, 0.60, 0.78, 0.86), ncol = 2, byrow = TRUE)
    for (i in seq_len(nrow(top))) {
      grid.rect(x = unit(mean(top[i, ]), "npc"), y = unit(top_y, "npc"), width = unit(diff(top[i, ]), "npc"), height = unit(0.07, "npc"), gp = gpar(fill = cols[i], col = "#333333", lwd = 0.2))
      grid.rect(x = unit(mean(bot[i, ]), "npc"), y = unit(bot_y, "npc"), width = unit(diff(bot[i, ]), "npc"), height = unit(0.07, "npc"), gp = gpar(fill = cols[i], col = "#333333", lwd = 0.2))
      grid.polygon(unit(c(top[i, 1], top[i, 2], bot[i, 2], bot[i, 1]), "npc"), unit(c(top_y - 0.04, top_y - 0.04, bot_y + 0.04, bot_y + 0.04), "npc"), gp = gpar(fill = pale_cols[i], col = NA))
    }
  }
  pushViewport(viewport(x = unit(0.75, "npc"), y = unit(0.27, "npc"), width = unit(0.42, "npc"), height = unit(0.36, "npc")))
  draw_synteny()
  upViewport()
  grid.text("C", x = unit(0.52, "npc"), y = unit(0.47, "npc"), just = c("left", "top"), gp = gpar(fontsize = 12, fontface = "bold"))
})

save_svg("biology_transcriptomics", 7.1, 4.8, function() {
  n <- 700
  vol <- data.frame(log2fc = rnorm(n, 0, 1.15), fdr = pmin(runif(n) ^ 2, 0.99))
  vol$neglog10 <- -log10(vol$fdr)
  vol$class <- ifelse(vol$fdr < 0.05 & vol$log2fc > 1, "Up", ifelse(vol$fdr < 0.05 & vol$log2fc < -1, "Down", "NS"))
  p_vol <- ggplot(vol, aes(log2fc, neglog10, color = class)) +
    geom_point(size = 0.58) +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.23, color = "#666666") +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.23, color = "#666666") +
    scale_color_manual(values = c(Down = pal_npg[["cyan"]], NS = "#B8B8B8", Up = pal_npg[["red"]])) +
    labs(title = "Differential expression", x = expression(log[2]("fold change")), y = expression(-log[10]("FDR")), color = NULL) +
    pub_theme(6.3, FALSE) +
    theme(legend.position = c(0.04, 0.96), legend.justification = c(0, 1))

  corr_ids <- paste0(rep(c("A", "B"), each = 4), 1:4)
  corr <- outer(seq_along(corr_ids), seq_along(corr_ids), function(i, j) 0.72 + 0.20 * (substr(corr_ids[i], 1, 1) == substr(corr_ids[j], 1, 1)) - 0.018 * abs(i - j))
  diag(corr) <- 1
  corr_df <- expand.grid(x = corr_ids, y = corr_ids, KEEP.OUT.ATTRS = FALSE)
  corr_df$r <- as.vector(corr)
  corr_df$x <- factor(corr_df$x, levels = corr_ids)
  corr_df$y <- factor(corr_df$y, levels = rev(corr_ids))
  corr_df$bin <- cut(corr_df$r, breaks = c(0.70, 0.82, 0.88, 0.94, 1.01), include.lowest = TRUE,
                     labels = c("0.70-0.82", "0.82-0.88", "0.88-0.94", "0.94-1.00"))
  p_corr <- ggplot(corr_df, aes(x, y, fill = bin)) +
    geom_tile(color = tile_border, linewidth = 0.12) +
    scale_fill_manual(values = c("0.70-0.82" = "#D7E8F3", "0.82-0.88" = "#91D1C2", "0.88-0.94" = "#4DBBD5", "0.94-1.00" = "#3C5488"), name = "r") +
    labs(title = "Sample correlation", x = NULL, y = NULL) +
    pub_theme(6.0, FALSE) +
    theme(axis.ticks = element_blank(), axis.line = element_blank())

  p_heat <- make_theme_plots(palettes$omics)$heat + labs(title = "Expression heatmap")
  ma_df <- data.frame(base = 10 ^ runif(n, 1, 5), fc = rnorm(n, 0, 0.55), fdr = pmin(runif(n) ^ 2.2, 0.99))
  ma_df$class <- ifelse(ma_df$fdr < 0.05 & ma_df$fc > 1, "Up", ifelse(ma_df$fdr < 0.05 & ma_df$fc < -1, "Down", "NS"))
  p_ma <- ggplot(ma_df, aes(log10(base), fc, color = class)) +
    geom_hline(yintercept = 0, color = "#D9D9D9", linewidth = 0.25) +
    geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "#666666", linewidth = 0.22) +
    geom_point(size = 0.58) +
    scale_color_manual(values = c(Down = pal_npg[["cyan"]], NS = "#B8B8B8", Up = pal_npg[["red"]])) +
    labs(title = "MA pattern", x = expression(log[10]("mean expression")), y = expression(log[2]("fold change"))) +
    pub_theme(6.3, FALSE)
  grid.newpage(); grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(p_heat, 0.27, 0.70, 0.42, 0.38, "A")
  draw_plot(p_vol, 0.75, 0.70, 0.42, 0.38, "B")
  draw_plot(p_corr, 0.27, 0.25, 0.42, 0.38, "C")
  draw_plot(p_ma, 0.75, 0.25, 0.42, 0.38, "D")
})

save_svg("biology_proteomics", 7.1, 4.8, function() {
  proteins <- paste0("Prot", sprintf("%02d", 1:16))
  samples <- paste0(rep(c("Ctrl", "Treat"), each = 4), rep(1:4, 2))
  prot <- expand.grid(protein = proteins, sample = samples, KEEP.OUT.ATTRS = FALSE)
  prot$protein <- factor(prot$protein, levels = rev(proteins))
  prot$sample <- factor(prot$sample, levels = samples)
  prot$value <- rnorm(nrow(prot), 0, 0.55) + rep(seq(-0.8, 0.8, length.out = length(proteins)), each = length(samples)) / 2
  prot$bin <- cut(prot$value, breaks = c(-Inf, -1.0, -0.35, 0.35, 1.0, Inf),
                  labels = c("low", "mild low", "mid", "mild high", "high"))
  p_heat <- ggplot(prot, aes(sample, protein, fill = bin)) +
    geom_tile(color = tile_border, linewidth = 0.12) +
    scale_fill_manual(values = c("low" = "#355C7D", "mild low" = "#7D9DBA", "mid" = neutral_mid, "mild high" = "#E2A0B0", "high" = "#C06C84"), name = "z bin") +
    labs(title = "Protein abundance", x = "LC-MS/MS samples", y = NULL) +
    pub_theme(6.2, FALSE) +
    theme(axis.ticks = element_blank(), axis.line = element_blank())

  domains <- data.frame(domain = c("Signal", "Kinase", "Regulatory"), start = c(18, 95, 235), end = c(58, 205, 310), y = 1)
  sites <- data.frame(pos = c(42, 120, 166, 248, 288, 330), score = c(0.5, 0.9, 0.65, 0.8, 0.55, 0.35), type = c("PTM", "PTM", "variant", "PTM", "variant", "PTM"))
  p_lolli <- ggplot() +
    geom_segment(aes(x = 1, xend = 360, y = 1, yend = 1), color = "#444444", linewidth = 0.7) +
    geom_rect(data = domains, aes(xmin = start, xmax = end, ymin = 0.86, ymax = 1.14, fill = domain), color = "#333333", linewidth = 0.15) +
    geom_segment(data = sites, aes(x = pos, xend = pos, y = 1.15, yend = 1.15 + score * 0.58, color = type), linewidth = 0.30) +
    geom_point(data = sites, aes(x = pos, y = 1.15 + score * 0.58, color = type), size = 1.5) +
    scale_fill_manual(values = c(Signal = "#99B898", Kinase = "#355C7D", Regulatory = "#F8B195")) +
    scale_color_manual(values = c(PTM = "#C06C84", variant = "#2A9D8F")) +
    scale_y_continuous(NULL, breaks = NULL, limits = c(0.75, 1.9)) +
    labs(title = "Domain and PTM sites", x = "Protein coordinate (aa)", fill = NULL, color = NULL) +
    pub_theme(6.3, FALSE) +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), legend.position = "bottom")

  eff <- effect_df
  p_eff <- ggplot(eff, aes(estimate, module)) +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.25, color = "#666666") +
    geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.12, linewidth = 0.42, color = "#C06C84") +
    geom_point(size = 1.5, color = "#355C7D") +
    labs(title = "Protein module effects", x = "Effect (95% CI)", y = NULL) +
    pub_theme(6.3, FALSE)

  grid.newpage(); grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(p_heat, 0.27, 0.70, 0.42, 0.38, "A")
  draw_plot(p_lolli, 0.75, 0.70, 0.42, 0.38, "B")
  draw_plot(p_eff, 0.27, 0.25, 0.42, 0.38, "C")
  draw_plot(standard_enrichment_dot(enrich_df, "Protein function terms"), 0.75, 0.25, 0.42, 0.38, "D")
})

save_svg("biology_functional", 7.1, 4.8, function() {
  bar_df <- enrich_df[order(enrich_df$fdr, decreasing = TRUE), ]
  bar_df$neglog10_fdr <- -log10(bar_df$fdr)
  bar_df$term <- factor(bar_df$term, levels = bar_df$term)
  p_bar <- ggplot(bar_df, aes(neglog10_fdr, term, fill = neglog10_fdr)) +
    geom_col(width = 0.58, color = "#333333", linewidth = 0.16) +
    scale_fill_gradientn(colors = c("#3C5488", "#4DBBD5", "#00A087", "#F39B7F", "#E64B35"), guide = "none") +
    labs(title = "Ranked term evidence", x = expression(-log[10]("FDR")), y = NULL) +
    pub_theme(6.4, FALSE) +
    theme(legend.position = "none")
  p_dot <- standard_enrichment_dot(enrich_df, "Enrichment dot plot")
  grid.newpage(); grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(p_bar, 0.27, 0.70, 0.42, 0.38, "A")
  draw_plot(p_dot, 0.75, 0.70, 0.42, 0.38, "B")
  pushViewport(viewport(x = unit(0.50, "npc"), y = unit(0.24, "npc"), width = unit(0.88, "npc"), height = unit(0.33, "npc")))
  grid.rect(gp = gpar(fill = "white", col = NA))
  grid.text("C", x = unit(0.00, "npc"), y = unit(1.04, "npc"), just = c("left", "top"), gp = gpar(fontsize = 12, fontface = "bold"))
  grid.text("Category transitions", x = unit(0.04, "npc"), y = unit(0.93, "npc"), just = "left", gp = gpar(fontsize = 8, fontface = "bold"))
  x <- c(0.18, 0.50, 0.82)
  grid.text(c("Stage 1", "Stage 2", "Stage 3"), x = unit(x, "npc"), y = unit(0.80, "npc"), gp = gpar(fontsize = 7.2, fontface = "bold"))
  flow_cols <- c("#4C78A8", "#59A14F", "#F2B701", "#E45756")
  for (i in seq_along(flow_cols)) {
    y0 <- 0.62 - (i - 1) * 0.12
    grid.bezier(x = unit(c(x[1], 0.32, 0.38, x[2]), "npc"),
                y = unit(c(y0, y0 + 0.06, y0 + 0.02, y0 - 0.03), "npc"),
                gp = gpar(col = flow_cols[i], lwd = 10 - i, lineend = "round"))
    grid.bezier(x = unit(c(x[2], 0.62, 0.68, x[3]), "npc"),
                y = unit(c(y0 - 0.03, y0 - 0.08, y0 + 0.03, y0 - 0.06), "npc"),
                gp = gpar(col = flow_cols[i], lwd = 10 - i, lineend = "round"))
  }
  for (xx in x) grid.lines(unit(c(xx, xx), "npc"), unit(c(0.24, 0.70), "npc"), gp = gpar(col = "#222222", lwd = 0.8))
  upViewport()
})

save_svg("biology_faceted_epigenomics", 7.1, 4.8, function() {
  species <- c("A. marina", "R. apiculata")
  contexts <- c("CG", "CHG", "CHH")
  species_labs <- as_labeller(c(
    "A. marina" = "italic('A. marina')",
    "R. apiculata" = "italic('R. apiculata')"
  ), label_parsed)

  meth <- expand.grid(stage = 1:5, species = species, context = contexts, KEEP.OUT.ATTRS = FALSE)
  meth$base <- c(CG = 0.73, CHG = 0.42, CHH = 0.17)[meth$context]
  meth$species_shift <- ifelse(meth$species == "A. marina", 0.02, -0.015)
  meth$mean <- meth$base + meth$species_shift + (meth$stage - 3) * c(CG = 0.012, CHG = -0.004, CHH = 0.018)[meth$context]
  meth$se <- c(CG = 0.012, CHG = 0.014, CHH = 0.010)[meth$context]
  meth$stage_label <- factor(paste0("S", meth$stage), levels = paste0("S", 1:5))
  p_meth <- ggplot(meth, aes(stage_label, mean, group = 1, color = context)) +
    geom_errorbar(aes(ymin = mean - 1.96 * se, ymax = mean + 1.96 * se), width = 0.10, linewidth = 0.25) +
    geom_line(linewidth = 0.42) +
    geom_point(size = 0.95) +
    facet_grid(species ~ context, labeller = labeller(species = species_labs)) +
    scale_color_manual(values = context_cols, guide = "none") +
    scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0.08, 0.82)) +
    labs(title = "Faceted methylation contexts", x = "Stage", y = "mC level") +
    pub_theme(5.8, TRUE) +
    theme(strip.text = element_text(size = 5.9, face = "bold"),
          panel.border = element_rect(color = "#BDBDBD", fill = NA, linewidth = 0.22),
          legend.position = "none")

  dmr <- expand.grid(context = contexts, species = species, locus = 1:85, KEEP.OUT.ATTRS = FALSE)
  dmr$delta <- rnorm(nrow(dmr), 0, 0.15) + ifelse(dmr$context == "CHH", 0.04, 0) + ifelse(dmr$species == "R. apiculata", -0.025, 0)
  dmr$fdr <- pmin(runif(nrow(dmr)) ^ 2.4, 0.98)
  dmr$status <- ifelse(dmr$fdr < 0.05 & dmr$delta > 0.12, "Hyper",
                       ifelse(dmr$fdr < 0.05 & dmr$delta < -0.12, "Hypo", "Stable"))
  p_dmr <- ggplot(dmr, aes(delta, -log10(fdr), color = status)) +
    geom_point(size = 0.45) +
    geom_vline(xintercept = c(-0.12, 0.12), linetype = "dashed", linewidth = 0.20, color = "#666666") +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.20, color = "#666666") +
    facet_wrap(~ context, nrow = 1) +
    scale_color_manual(values = dmr_cols, breaks = c("Hyper", "Hypo", "Stable")) +
    labs(title = "DMR volcano by context", x = expression(Delta*" methylation"), y = expression(-log[10]("FDR")), color = NULL) +
    pub_theme(5.9, FALSE) +
    theme(strip.text = element_text(size = 6.0, face = "bold"),
          legend.position = c(0.02, 0.98), legend.justification = c(0, 1))

  epi_signal <- expand.grid(pos = seq(0, 100, length.out = 120), context = contexts, species = species, KEEP.OUT.ATTRS = FALSE)
  epi_signal$value <- c(CG = 0.70, CHG = 0.38, CHH = 0.16)[epi_signal$context] +
    0.05 * sin(epi_signal$pos / c(CG = 18, CHG = 12, CHH = 9)[epi_signal$context]) +
    ifelse(epi_signal$species == "A. marina", 0.018, -0.010)
  track_anno <- data.frame(
    xmin = c(8, 24, 46, 68, 16, 58, 76),
    xmax = c(17, 33, 55, 82, 23, 66, 90),
    ymin = c(-0.12, -0.12, -0.12, -0.12, -0.20, -0.20, -0.20),
    ymax = c(-0.07, -0.07, -0.07, -0.07, -0.15, -0.15, -0.15),
    feature = c("Gene", "TE", "TE", "Gene", "24-nt siRNA", "RdDM", "24-nt siRNA")
  )
  p_track <- ggplot(epi_signal, aes(pos, value, color = context)) +
    geom_rect(data = track_anno, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = feature),
              inherit.aes = FALSE, color = "#333333", linewidth = 0.12) +
    geom_line(linewidth = 0.42) +
    facet_wrap(~ species, ncol = 1, labeller = labeller(species = species_labs)) +
    scale_color_manual(values = context_cols, name = "Context") +
    scale_fill_manual(values = epigenome_cols, name = "Track") +
    scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(-0.24, 0.82)) +
    labs(title = "Epigenomic tracks", x = "Position (kb)", y = "mC") +
    pub_theme(5.9, FALSE) +
    theme(strip.text = element_text(size = 6.0, face = "bold"),
          legend.position = "bottom")

  draw_epi_legend <- function() {
    grid.rect(gp = gpar(fill = "white", col = NA))
    grid.text("Epigenetic legend grammar", x = unit(0.03, "npc"), y = unit(0.94, "npc"), just = "left",
              gp = gpar(fontsize = 8, fontface = "bold", col = "#222222"))
    draw_group <- function(title, cols, x0, y0) {
      grid.text(title, x = unit(x0, "npc"), y = unit(y0, "npc"), just = "left",
                gp = gpar(fontsize = 6.9, fontface = "bold", col = "#333333"))
      for (i in seq_along(cols)) {
        yy <- y0 - 0.10 - (i - 1) * 0.078
        grid.rect(x = unit(x0 + 0.025, "npc"), y = unit(yy, "npc"),
                  width = unit(0.045, "npc"), height = unit(0.040, "npc"),
                  gp = gpar(fill = cols[[i]], col = "#333333", lwd = 0.2))
        grid.text(names(cols)[i], x = unit(x0 + 0.065, "npc"), y = unit(yy, "npc"), just = "left",
                  gp = gpar(fontsize = 6.2, col = "#333333"))
      }
    }
    draw_group("Methylation context", context_cols, 0.05, 0.78)
    draw_group("DMR direction", dmr_cols, 0.05, 0.42)
    draw_group("Genome annotation", epigenome_cols, 0.52, 0.78)
    grid.text("Stable colors across panels.",
              x = unit(0.05, "npc"), y = unit(0.08, "npc"), just = "left",
              gp = gpar(fontsize = 5.7, col = "#555555"))
  }

  grid.newpage(); grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(p_meth, 0.30, 0.70, 0.48, 0.38, "A")
  draw_plot(p_dmr, 0.78, 0.70, 0.36, 0.38, "B")
  draw_plot(p_track, 0.30, 0.25, 0.48, 0.38, "C")
  pushViewport(viewport(x = unit(0.78, "npc"), y = unit(0.25, "npc"), width = unit(0.36, "npc"), height = unit(0.38, "npc")))
  draw_epi_legend()
  upViewport()
  grid.text("D", x = unit(0.59, "npc"), y = unit(0.47, "npc"), just = c("left", "top"),
            gp = gpar(fontsize = 12, fontface = "bold", col = "#222222"))
})

save_svg("panel_assembly_balanced", 7.1, 4.8, function() {
  plots <- make_quant_plots()
  grid.newpage(); grid.rect(gp = gpar(fill = "white", col = NA))
  draw_plot(plots$bar, 0.27, 0.70, 0.42, 0.38, "A")
  draw_plot(plots$box, 0.75, 0.70, 0.42, 0.38, "B")
  draw_plot(plots$violin, 0.27, 0.25, 0.42, 0.38, "C")
  draw_plot(plots$line, 0.75, 0.25, 0.42, 0.38, "D")
})
