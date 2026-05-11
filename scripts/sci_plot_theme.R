#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

# Publication geometry. Values are in inches and match common single/double
# column journal artwork widths.
SCI_WIDTH_SINGLE <- 3.35
SCI_WIDTH_ONE_HALF <- 5.10
SCI_WIDTH_DOUBLE <- 7.08
SCI_DPI_PRINT <- 600

sci_fig_size <- function(layout = c("single", "one_half", "double"),
                         height = NULL,
                         aspect = 0.62,
                         min_height = 1.85,
                         max_height = 6.20) {
  layout <- match.arg(layout)
  width <- switch(
    layout,
    single = SCI_WIDTH_SINGLE,
    one_half = SCI_WIDTH_ONE_HALF,
    double = SCI_WIDTH_DOUBLE
  )
  if (is.null(height)) {
    height <- min(max(width * aspect, min_height), max_height)
  }
  list(width = width, height = height)
}

sci_palettes <- list(
  okabe_ito = c(
    blue = "#0072B2",
    vermillion = "#D55E00",
    green = "#009E73",
    purple = "#CC79A7",
    orange = "#E69F00",
    sky = "#56B4E9",
    yellow = "#F0E442",
    gray = "#7A7A7A"
  ),
  npg_like = c(
    red = "#E64B35",
    cyan = "#4DBBD5",
    teal = "#00A087",
    navy = "#3C5488",
    salmon = "#F39B7F",
    lavender = "#8491B4",
    mint = "#91D1C2",
    crimson = "#DC0000",
    brown = "#7E6148",
    sand = "#B09C85"
  ),
  aaas_like = c(
    blue = "#3B4992",
    red = "#EE0000",
    green = "#008B45",
    purple = "#631879",
    ochre = "#BB0021",
    cyan = "#008280",
    gray = "#808180"
  ),
  lancet_like = c(
    blue = "#00468B",
    red = "#ED0000",
    green = "#42B540",
    cyan = "#0099B4",
    purple = "#925E9F",
    salmon = "#FDAF91",
    crimson = "#AD002A",
    gray = "#ADB6B6"
  )
)

species_palette <- c(
  Atha = "#4C78A8",
  Amar = "#B94B48",
  Apan = "#A3BE8C",
  Rapi = "#3F7F9F",
  Ptri = "#7B8DA0",
  Cpec = "#6D8FA3"
)

species_label_expr <- c(
  Atha = "italic('A. thaliana')",
  Amar = "italic('A. marina')",
  Apan = "italic('A. paniculata')",
  Rapi = "italic('R. apiculata')",
  Ptri = "italic('P. trichocarpa')",
  Cpec = "italic('C. pectinifolia')",
  "A. thaliana" = "italic('A. thaliana')",
  "A. marina" = "italic('A. marina')",
  "A. paniculata" = "italic('A. paniculata')",
  "R. apiculata" = "italic('R. apiculata')",
  "P. trichocarpa" = "italic('P. trichocarpa')",
  "C. pectinifolia" = "italic('C. pectinifolia')"
)

context_palette <- c(CG = "#E64B35", CHG = "#4DBBD5", CHH = "#00A087")
dmr_palette <- c(Hyper = "#E64B35", Hypo = "#3C5488", Stable = "#9A9A9A")
epigenome_track_palette <- c(
  Gene = "#3C5488",
  TE = "#7E6148",
  `24-nt siRNA` = "#00A087",
  RdDM = "#8491B4",
  DMR = "#E64B35"
)
effect_palette <- c(Down = "#4DBBD5", NS = "#B8B8B8", Up = "#E64B35")
evidence_palette <- c(
  observed = "#3C5488",
  associated = "#00A087",
  candidate = "#F39B7F",
  inferred = "#8491B4",
  proposed = "#9A9A9A"
)
missing_value_color <- "#CFCFCF"
neutral_mid_color <- "#E6E6E6"
tile_border_color <- "#F0F0F0"

species_axis_labels <- function(x) {
  labels <- vapply(as.character(x), function(xx) {
    if (xx %in% names(species_label_expr)) {
      species_label_expr[[xx]]
    } else {
      paste0("'", gsub("'", "\\\\'", xx), "'")
    }
  }, character(1))
  parse(text = labels)
}

species_facet_labeller <- function() {
  as_labeller(species_label_expr, default = label_parsed)
}

theme_sci <- function(base_size = 7, base_family = "Arial", grid = FALSE) {
  base <- if (grid) {
    theme_minimal(base_size = base_size, base_family = base_family)
  } else {
    theme_classic(base_size = base_size, base_family = base_family)
  }
  base +
    theme(
      text = element_text(color = "#222222"),
      axis.title = element_text(size = base_size + 0.5),
      axis.text = element_text(size = base_size, color = "#222222"),
      axis.line = element_line(linewidth = 0.35, color = "#222222"),
      axis.ticks = element_line(linewidth = 0.30, color = "#222222"),
      axis.ticks.length = unit(1.4, "mm"),
      panel.grid.major = if (grid) element_line(linewidth = 0.22, color = "#E7E7E7") else element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_text(size = base_size, face = "bold"),
      legend.text = element_text(size = base_size - 0.5),
      legend.key.size = unit(3.0, "mm"),
      legend.background = element_blank(),
      legend.box.background = element_blank(),
      plot.title = element_text(size = base_size + 1, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = base_size, hjust = 0),
      plot.margin = margin(4, 4, 4, 4, unit = "pt"),
      strip.background = element_blank(),
      strip.text = element_text(size = base_size, face = "bold")
    )
}

theme_sci_heatmap <- function(base_size = 6.5) {
  theme_sci(base_size = base_size) +
    theme(
      axis.line = element_blank(),
      axis.ticks = element_blank(),
      panel.border = element_blank()
    )
}

theme_sci_facet <- function(base_size = 6.5,
                            strip_fill = "#F2F2F2",
                            border_color = "#BDBDBD") {
  theme_sci(base_size = base_size, grid = TRUE) +
    theme(
      panel.border = element_rect(color = border_color, fill = NA, linewidth = 0.25),
      strip.background = element_rect(fill = strip_fill, color = border_color, linewidth = 0.25),
      strip.text = element_text(size = base_size, face = "bold")
    )
}

scale_x_species <- function(..., drop = FALSE) {
  scale_x_discrete(labels = species_axis_labels, drop = drop, ...)
}

scale_y_species <- function(..., drop = FALSE) {
  scale_y_discrete(labels = species_axis_labels, drop = drop, ...)
}

scale_color_species <- function(..., drop = FALSE) {
  scale_color_manual(values = species_palette, labels = species_axis_labels, drop = drop, ...)
}

scale_fill_species <- function(..., drop = FALSE) {
  scale_fill_manual(values = species_palette, labels = species_axis_labels, drop = drop, ...)
}

scale_color_context <- function(...) {
  scale_color_manual(values = context_palette, breaks = c("CG", "CHG", "CHH"), ...)
}

scale_fill_context <- function(...) {
  scale_fill_manual(values = context_palette, breaks = c("CG", "CHG", "CHH"), ...)
}

scale_color_dmr <- function(...) {
  scale_color_manual(values = dmr_palette, breaks = c("Hyper", "Hypo", "Stable"), ...)
}

scale_fill_dmr <- function(...) {
  scale_fill_manual(values = dmr_palette, breaks = c("Hyper", "Hypo", "Stable"), ...)
}

scale_color_effect <- function(...) {
  scale_color_manual(values = effect_palette, breaks = c("Down", "NS", "Up"), ...)
}

scale_fill_effect <- function(...) {
  scale_fill_manual(values = effect_palette, breaks = c("Down", "NS", "Up"), ...)
}

scale_color_fdr <- function(name = expression(-log[10]("FDR")), ...) {
  scale_color_gradientn(
    colors = c("#3C5488", "#4DBBD5", "#00A087", "#F39B7F", "#E64B35"),
    name = name,
    ...
  )
}

scale_fill_fdr <- function(name = expression(-log[10]("FDR")), ...) {
  scale_fill_gradientn(
    colors = c("#3C5488", "#4DBBD5", "#00A087", "#F39B7F", "#E64B35"),
    name = name,
    ...
  )
}

scale_fill_z <- function(name = "z", ...) {
  scale_fill_gradient2(
    low = "#3C5488",
    mid = neutral_mid_color,
    high = "#E64B35",
    midpoint = 0,
    na.value = missing_value_color,
    name = name,
    ...
  )
}

sci_save_plot <- function(plot,
                          filename,
                          layout = c("double", "single", "one_half"),
                          height = NULL,
                          aspect = 0.62,
                          dpi = SCI_DPI_PRINT,
                          device = NULL) {
  layout <- match.arg(layout)
  dims <- sci_fig_size(layout = layout, height = height, aspect = aspect)
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  ext <- tolower(tools::file_ext(filename))
  if (is.null(device)) {
    device <- switch(ext, pdf = "pdf", svg = "svg", png = "png", tiff = "tiff", tif = "tiff", "pdf")
  }
  if (device == "pdf") {
    ggsave(filename, plot = plot, width = dims$width, height = dims$height,
           device = grDevices::pdf, useDingbats = FALSE)
  } else if (device == "svg") {
    ggsave(filename, plot = plot, width = dims$width, height = dims$height,
           device = grDevices::svg)
  } else {
    ggsave(filename, plot = plot, width = dims$width, height = dims$height,
           dpi = dpi, device = device)
  }
  invisible(filename)
}

sci_warn_palette <- function(values, allow_white_background = TRUE) {
  hex <- toupper(gsub("\\s+", "", unname(values)))
  white_like <- hex %in% c("#FFFFFF", "WHITE", "#FFF")
  if (any(white_like) && !allow_white_background) {
    warning("Palette uses white as a data color; use light gray for neutral or missing values.")
  }
  invisible(values)
}
