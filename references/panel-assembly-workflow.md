# Panel Assembly Workflow

Use this reference when combining independently generated panels into a journal-ready multi-panel figure.

## Core Principle

Keep source panels label-free. Add `A`, `B`, `C`, etc. only during assembly. This makes panel order, replacement, and journal-driven layout changes reversible without editing the single-panel exports.

## Recommended Solution

Use two assembly routes:

1. **Vector route: LaTeX assembler**
   - Script: `scripts/assemble_panels_latex.py`
   - Best for: PDF panels from R/ggplot2, matplotlib, Illustrator, Inkscape, or vector schematics.
   - Strength: preserves vector text and lines in the final composite PDF.
   - Weakness: less flexible for photos, microscopy panels, and mixed raster/vector layouts.

2. **Raster/mixed route: R magick assembler**
   - Script: `scripts/assemble_panels_magick.R`
   - Best for: PNG/TIFF/JPEG, microscopy, phenotype photos, screenshots, mixed PDF/PNG panels, and quick layout previews.
   - Strength: uses ImageMagick in the `rna` conda environment, adds external labels, generates high-resolution PNG and optional PDF.
   - Weakness: PDF input is rasterized, so use the vector route for final data-plot PDFs when possible.

If all panels are generated inside one R script as ggplot objects, use `patchwork` or `cowplot` directly. If panels already exist as files, use one of the two assemblers above.

In the `rna` conda environment, the mixed-panel route can use R 4.5, `magick`, `png`, `cowplot`, `patchwork`, `gridExtra`, `ragg`, ImageMagick, `rsvg-convert`, and Poppler (`pdftoppm`). This makes automated assembly realistic for previews and many raster/mixed final figures.

## Layout Rules

- Choose final width first: 85-90 mm for single-column, 170-180 mm for double-column.
- Keep source panel aspect ratios stable.
- Do not force single-column, double-column, and very different aspect-ratio panels into the same regular grid; it creates large blank areas. Group matched panels together, use spanning layouts, or assemble those figures manually.
- Use consistent horizontal and vertical gaps, usually 3-5 mm.
- Reserve a small label band above panels or place labels just outside the upper-left panel boundary.
- Align panels by their outer bounding boxes, not by visual guesswork.
- Put detailed panel descriptions in the legend, not inside the plot area.
- Build the composite from a manifest or command line so panel order is reproducible.

## LaTeX Vector Assembly

Example:

```bash
python /data/users/chenming/.codex/skills/sci-paper-optimizer/scripts/assemble_panels_latex.py \
  --panels A=panel_1.pdf B=panel_2.pdf C=panel_3.pdf D=panel_4.pdf \
  --layout 2x2 \
  --width-mm 178 \
  --gap-mm 4 \
  --row-gap-mm 4 \
  --out Figure1_composite.pdf
```

Use this for final publication PDFs when all panels are vector-friendly.

## R Magick Mixed Assembly

Run inside the `rna` conda environment or through `conda run -n rna`:

```bash
conda run -n rna Rscript /data/users/chenming/.codex/skills/sci-paper-optimizer/scripts/assemble_panels_magick.R \
  --panels A=panel_1.png B=panel_2.pdf C=panel_3.png D=panel_4.png \
  --layout 2x2 \
  --width-mm 178 \
  --dpi 300 \
  --out Figure1_composite.png \
  --pdf Figure1_composite_raster.pdf
```

Use this for mixed panel types, photos, microscopy, and previews. For print submission, check the journal's required raster format and DPI.

## Manifest Pattern

Use a TSV manifest when the figure has many panels:

```tsv
label	path
A	results/panels/Fig1A_design.pdf
B	results/panels/Fig1B_timecourse.pdf
C	results/panels/Fig1C_heatmap.pdf
D	results/panels/Fig1D_model.pdf
```

Then run:

```bash
conda run -n rna Rscript /data/users/chenming/.codex/skills/sci-paper-optimizer/scripts/assemble_panels_magick.R \
  --manifest Fig1_panels.tsv \
  --layout 2x2 \
  --out Fig1_composite.png
```

For the LaTeX assembler, pass panel order through the command line or a JSON config when needed.

JSON config example for LaTeX:

```json
{
  "layout": "2x2",
  "width_mm": 178,
  "gap_mm": 4,
  "row_gap_mm": 4,
  "panels": [
    {"label": "A", "path": "results/panels/Fig1A_design.pdf"},
    {"label": "B", "path": "results/panels/Fig1B_timecourse.pdf"},
    {"label": "C", "path": "results/panels/Fig1C_heatmap.pdf"},
    {"label": "D", "path": "results/panels/Fig1D_model.pdf"}
  ]
}
```

## When Not To Auto-Assemble

Use Illustrator, Inkscape, Affinity Designer, or manual layout when:

- Panels need irregular cropping or non-rectangular alignment.
- Microscopy panels need precise scale-bar placement across subpanels.
- A schematic and photos require hand-tuned visual hierarchy.
- The journal requests editable layered artwork.
- Automated output looks crowded after two layout attempts.

In these cases, still keep the manifest and label-free source panels so manual edits remain traceable.

## Final Checks

- Source panels remain label-free.
- Composite has the correct A/B/C order.
- Labels are outside or cleanly separated from the panel data.
- No labels cover axes, legends, scale bars, or image content.
- Gaps are consistent.
- Figure width matches target column width.
- Text remains readable at final export size.
- Output is nonempty and opens correctly.
- Vector route is used for final data plots when possible.
