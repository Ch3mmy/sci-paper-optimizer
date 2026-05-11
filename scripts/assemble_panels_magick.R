#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(magick)
  library(grid)
})

usage <- function() {
  cat("Usage:\n")
  cat("  Rscript assemble_panels_magick.R --panels A=panel1.png B=panel2.pdf --layout 2x2 --out Figure1.png [--pdf Figure1.pdf]\n")
  cat("  Rscript assemble_panels_magick.R --manifest panels.tsv --layout 2x2 --out Figure1.png\n\n")
  cat("Manifest TSV columns: label, path. Source panels should be label-free.\n")
}

parse_args <- function(args) {
  out <- list(
    panels = character(),
    manifest = NA_character_,
    layout = "2x2",
    out = NA_character_,
    pdf = NA_character_,
    width_mm = 178,
    dpi = 300,
    gap_mm = 4,
    row_gap_mm = 4,
    label_space_mm = 4,
    label_size_pt = 10,
    label_x_mm = 0,
    label_y_mm = 0.8,
    background = "white"
  )
  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    if (key == "--panels") {
      i <- i + 1
      vals <- character()
      while (i <= length(args) && !startsWith(args[[i]], "--")) {
        vals <- c(vals, args[[i]])
        i <- i + 1
      }
      out$panels <- vals
      next
    }
    if (!startsWith(key, "--")) stop("Unexpected argument: ", key)
    if (i == length(args)) stop("Missing value for ", key)
    val <- args[[i + 1]]
    name <- gsub("-", "_", sub("^--", "", key))
    if (!name %in% names(out)) stop("Unknown option: ", key)
    out[[name]] <- val
    i <- i + 2
  }
  numeric_fields <- c("width_mm", "dpi", "gap_mm", "row_gap_mm", "label_space_mm", "label_size_pt", "label_x_mm", "label_y_mm")
  for (f in numeric_fields) out[[f]] <- as.numeric(out[[f]])
  out
}

parse_layout <- function(layout) {
  parts <- strsplit(tolower(layout), "x", fixed = TRUE)[[1]]
  if (length(parts) != 2) stop("--layout must look like 2x2 or 3x2")
  dims <- as.integer(parts)
  if (any(is.na(dims)) || any(dims < 1)) stop("Invalid --layout: ", layout)
  dims
}

parse_panel <- function(raw) {
  parts <- strsplit(raw, "=", fixed = TRUE)[[1]]
  if (length(parts) != 2) stop("Panel must look like A=path: ", raw)
  data.frame(label = parts[[1]], path = normalizePath(parts[[2]], mustWork = TRUE), stringsAsFactors = FALSE)
}

read_panels <- function(cfg) {
  if (!is.na(cfg$manifest)) {
    dat <- read.delim(cfg$manifest, stringsAsFactors = FALSE, check.names = FALSE)
    if (!all(c("label", "path") %in% names(dat))) stop("Manifest must contain label and path columns")
    dat$path <- normalizePath(dat$path, mustWork = TRUE)
    return(dat[, c("label", "path"), drop = FALSE])
  }
  if (length(cfg$panels) == 0) stop("Provide --panels or --manifest")
  do.call(rbind, lapply(cfg$panels, parse_panel))
}

mm_to_px <- function(mm, dpi) round(mm / 25.4 * dpi)

convert_pdf_to_png <- function(path, dpi) {
  out_base <- tempfile("panel_pdf_")
  cmd <- c("-f", "1", "-singlefile", "-png", "-r", as.character(dpi), shQuote(path), shQuote(out_base))
  status <- system2("pdftoppm", cmd)
  out_file <- paste0(out_base, ".png")
  if (!identical(status, 0L) || !file.exists(out_file)) {
    stop("Failed to rasterize PDF with pdftoppm: ", path)
  }
  out_file
}

convert_svg_to_png <- function(path, dpi) {
  out_file <- tempfile("panel_svg_", fileext = ".png")
  status <- system2("rsvg-convert", c("-f", "png", "-d", as.character(dpi), "-p", as.character(dpi), "-o", shQuote(out_file), shQuote(path)))
  if (!identical(status, 0L) || !file.exists(out_file)) {
    stop("Failed to rasterize SVG with rsvg-convert: ", path)
  }
  out_file
}

read_image_any <- function(path, dpi) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "pdf") path <- convert_pdf_to_png(path, dpi)
  if (ext == "svg") path <- convert_svg_to_png(path, dpi)
  img <- image_read(path)
  img <- image_background(img, "white", flatten = TRUE)
  img
}

scale_to_width <- function(img, width_px) {
  image_scale(img, paste0(width_px, "x"))
}

draw_composite <- function(cells, panels, rows, cols, total_w_px, total_h_px, cell_w_px, gap_px, row_gap_px, label_space_px, label_x_px, label_y_px, label_size_pt, bg) {
  grid.newpage()
  grid.rect(gp = gpar(fill = bg, col = NA))
  y_top <- total_h_px
  for (r in seq_len(rows)) {
    row_idx <- ((r - 1) * cols + 1):(r * cols)
    row_h <- max(vapply(cells[row_idx], function(z) z$height, numeric(1)))
    x_left <- 0
    for (c in seq_len(cols)) {
      idx <- row_idx[[c]]
      if (!is.null(cells[[idx]]$raster)) {
        label <- cells[[idx]]$label
        img_h <- cells[[idx]]$height - label_space_px
        img_y_top <- y_top - label_space_px
        grid.text(
          label,
          x = unit((x_left + label_x_px) / total_w_px, "npc"),
          y = unit((y_top - label_y_px) / total_h_px, "npc"),
          just = c("left", "top"),
          gp = gpar(fontsize = label_size_pt, fontface = "bold", col = "#222222")
        )
        grid.raster(
          cells[[idx]]$raster,
          x = unit(x_left / total_w_px, "npc"),
          y = unit(img_y_top / total_h_px, "npc"),
          width = unit(cell_w_px / total_w_px, "npc"),
          height = unit(img_h / total_h_px, "npc"),
          just = c("left", "top"),
          interpolate = TRUE
        )
      }
      x_left <- x_left + cell_w_px + gap_px
    }
    y_top <- y_top - row_h
    if (r < rows) y_top <- y_top - row_gap_px
  }
}

write_outputs <- function(draw_fun, out_png, out_pdf, width_px, height_px, dpi, bg) {
  width_in <- width_px / dpi
  height_in <- height_px / dpi
  dir.create(dirname(normalizePath(out_png, mustWork = FALSE)), recursive = TRUE, showWarnings = FALSE)
  if (requireNamespace("ragg", quietly = TRUE)) {
    ragg::agg_png(out_png, width = width_px, height = height_px, units = "px", res = dpi, background = bg)
  } else {
    png(out_png, width = width_px, height = height_px, units = "px", res = dpi, bg = bg)
  }
  draw_fun()
  dev.off()
  cat("Wrote ", out_png, " (", file.info(out_png)$size, " bytes)\n", sep = "")
  if (!is.na(out_pdf)) {
    pdf(out_pdf, width = width_in, height = height_in, bg = bg, useDingbats = FALSE)
    draw_fun()
    dev.off()
    cat("Wrote ", out_pdf, " (", file.info(out_pdf)$size, " bytes)\n", sep = "")
  }
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) == 0 || "--help" %in% args) {
    usage()
    quit(status = ifelse("--help" %in% args, 0, 1))
  }
  cfg <- parse_args(args)
  if (is.na(cfg$out)) stop("--out is required")
  panels <- read_panels(cfg)
  dims <- parse_layout(cfg$layout)
  rows <- dims[[1]]
  cols <- dims[[2]]
  capacity <- rows * cols
  if (nrow(panels) > capacity) stop(nrow(panels), " panels do not fit in ", cfg$layout)

  total_w_px <- mm_to_px(cfg$width_mm, cfg$dpi)
  gap_px <- mm_to_px(cfg$gap_mm, cfg$dpi)
  row_gap_px <- mm_to_px(cfg$row_gap_mm, cfg$dpi)
  label_space_px <- mm_to_px(cfg$label_space_mm, cfg$dpi)
  label_x_px <- mm_to_px(cfg$label_x_mm, cfg$dpi)
  label_y_px <- mm_to_px(cfg$label_y_mm, cfg$dpi)
  cell_w_px <- floor((total_w_px - gap_px * (cols - 1)) / cols)
  if (cell_w_px <= 0) stop("Computed cell width is not positive")

  cells <- vector("list", capacity)
  for (i in seq_len(capacity)) {
    if (i <= nrow(panels)) {
      img <- scale_to_width(read_image_any(panels$path[[i]], cfg$dpi), cell_w_px)
      raster <- as.raster(img)
      info <- image_info(img)
      cells[[i]] <- list(label = panels$label[[i]], raster = raster, height = info$height + label_space_px)
    } else {
      cells[[i]] <- list(label = "", raster = NULL, height = label_space_px)
    }
  }
  row_heights <- vapply(seq_len(rows), function(r) {
    idx <- ((r - 1) * cols + 1):(r * cols)
    max(vapply(cells[idx], function(z) z$height, numeric(1)))
  }, numeric(1))
  total_h_px <- sum(row_heights) + row_gap_px * (rows - 1)

  draw_fun <- function() draw_composite(
    cells, panels, rows, cols, total_w_px, total_h_px, cell_w_px,
    gap_px, row_gap_px, label_space_px, label_x_px, label_y_px,
    cfg$label_size_pt, cfg$background
  )
  write_outputs(draw_fun, cfg$out, cfg$pdf, total_w_px, total_h_px, cfg$dpi, cfg$background)
}

main()
