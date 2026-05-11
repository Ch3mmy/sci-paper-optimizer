# Figure Theme Styles

Use this reference when a manuscript needs a unified visual identity across all figures. These profiles are journal-inspired rather than journal-branded; do not copy any publisher's proprietary templates or graphical style exactly.

## Theme Design Tokens

Define these tokens before producing final figures:

| Token | Recommended default |
| --- | --- |
| Background | White or near-white; avoid decorative backgrounds for data panels |
| Font | Arial, Helvetica, Source Sans, DejaVu Sans, or another clean sans-serif |
| Final tick text | Usually 6-7 pt minimum after journal-size export |
| Final axis/legend text | Usually 7-8 pt minimum |
| Panel label | Add during composite assembly; bold A/B/C or a/b/c depending on journal style |
| Axis line | 0.4-0.7 pt equivalent |
| Data line | 0.7-1.2 pt for final export; thicker only for emphasis |
| Grid | None or very light major grid; avoid heavy full grids |
| Error display | CI/SD/SEM stated explicitly; use intervals over stars when possible |
| Neutral color | Medium gray for baselines and secondary context |

## Recommended Theme Profiles

### 1. Evidence-First Minimal

Use for most biology, genomics, ecology, and experimental SCI manuscripts. This is the safest default for Nature/Science/New Phytologist/PNAS-style research figures.

- White background.
- No box around plot panel; keep left and bottom axes only.
- Thin axes and ticks.
- Minimal grid or no grid.
- Muted, colorblind-aware categorical palette.
- Strongest color reserved for the focal group or key contrast.
- Legends short and external when possible.
- Panel titles concise and result-oriented.

Palette:

- Focal blue: `#0072B2`
- Focal vermillion: `#D55E00`
- Teal: `#009E73`
- Purple: `#CC79A7`
- Gold: `#E69F00`
- Neutral gray: `#7A7A7A`
- Light gray: `#D9D9D9`

Use when in doubt.

Common journal-inspired categorical palettes can be used as starting points when
the manuscript needs richer color while retaining a restrained high-impact biology
look. Treat these as generic ggsci-style palettes, not as exact journal branding:

- NPG-like: `#E64B35`, `#4DBBD5`, `#00A087`, `#3C5488`, `#F39B7F`, `#8491B4`, `#91D1C2`, `#DC0000`.
- AAAS-like: `#3B4992`, `#EE0000`, `#008B45`, `#631879`, `#BB0021`, `#008280`, `#808180`.
- Lancet-like: `#00468B`, `#ED0000`, `#42B540`, `#0099B4`, `#925E9F`, `#FDAF91`, `#AD002A`, `#ADB6B6`.

Use these palettes to define a consistent visual identity, not to color every
available category. For dense heatmaps or epigenomics tracks, reserve gray for
missing/neutral values and avoid white as a meaningful data category.

### 2. Mechanism-Schematic Clean

Use for model figures, graphical summaries, pathway diagrams, and conceptual mechanisms.

- White or very pale background.
- Faint section bands only when they clarify compartments or phases.
- Solid arrows for observed/directly supported relations.
- Dashed arrows for inferred, candidate, or hypothesized relations.
- Minimal icons; labels and relationships matter more than decoration.
- Use no more than 3-5 main colors.
- Keep evidence-level labels visible: observed, associated, candidate, inferred, proposed.

Palette:

- Deep slate: `#2F3A45`
- Blue: `#4C78A8`
- Green: `#59A14F`
- Amber: `#F2B701`
- Red-orange: `#E45756`
- Pale band: `#F4F6F8`

### 3. Omics Matrix Compact

Use for heatmaps, expression/methylation matrices, evidence matrices, enrichment dot plots, and multi-layer summaries.

- Compact layout with strict factor ordering.
- Annotation strips for group, stage, tissue, treatment, or evidence class.
- Clear colorbar titles with units or transformed scale.
- Avoid uncontrolled clustering if it breaks the biological order.
- Use neutral gray for missing or not-applicable values, not white if white has data meaning.
- Keep row labels only when the number is small; move large label sets to tables.

Palettes:

- Diverging effect: `#2166AC` to `#F7F7F7` to `#B2182B`
- Sequential intensity: `#F7FBFF` to `#6BAED6` to `#08306B`
- Evidence class: `#4C78A8`, `#59A14F`, `#F2B701`, `#E45756`, `#9D9D9D`
- Missing/NA: `#CFCFCF`

### 4. Clinical/Effect-Size Clean

Use for clinical, epidemiology, treatment, risk, model-coefficient, odds-ratio, and meta-analysis style figures.

- Prioritize forest plots, coefficient plots, and absolute risk/effect displays.
- Show CI prominently.
- Use a vertical null line for ratio/effect plots.
- Keep colors conservative; avoid rainbow palettes.
- Put exact n, event counts, model adjustment, or endpoint definitions in the legend or table.

Palette:

- Primary estimate: `#1F77B4`
- Secondary estimate: `#8C8C8C`
- Harm/risk: `#C44E52`
- Benefit/protection: `#55A868`
- Reference/null: `#4D4D4D`

### 5. Ecology/Evolution Natural

Use for field biology, ecology, evolution, plant biology, environmental gradients, and organismal comparisons when a slightly natural palette helps interpretation.

- Still keep a white scientific-figure background.
- Use restrained earth/leaf/water colors for ecological groups.
- Avoid beige-dominated figures that reduce contrast.
- Pair color with shape or line type for species, habitats, or treatments.

Palette:

- Deep green: `#2E7D32`
- Blue-green: `#2A9D8F`
- Deep blue: `#3A6EA5`
- Ochre: `#C9A227`
- Clay red: `#B45F4D`
- Neutral gray: `#6E6E6E`

## Theme Selection Rules

- Use `Evidence-First Minimal` as the default for data panels.
- Use `Omics Matrix Compact` for dense high-dimensional biological data.
- Use `Mechanism-Schematic Clean` for conceptual models and pathways.
- Use `Clinical/Effect-Size Clean` when estimates, intervals, risks, or model coefficients are central.
- Use `Ecology/Evolution Natural` only when natural grouping improves interpretation.
- Do not combine more than two profiles in one manuscript: usually one data theme plus one schematic theme.

## R ggplot2 Theme Template

For production work, prefer sourcing `scripts/sci_plot_theme.R` so dimensions,
palettes, scales, and save functions stay consistent across panels. The template
below shows the core style if a standalone snippet is needed; adjust only after
inspecting final exports.

```r
theme_sci_minimal <- function(base_size = 7, base_family = "Arial") {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(color = "#222222"),
      axis.title = ggplot2::element_text(size = base_size + 0.5),
      axis.text = ggplot2::element_text(size = base_size, color = "#222222"),
      axis.line = ggplot2::element_line(linewidth = 0.35, color = "#222222"),
      axis.ticks = ggplot2::element_line(linewidth = 0.3, color = "#222222"),
      axis.ticks.length = grid::unit(1.5, "mm"),
      legend.title = ggplot2::element_text(size = base_size),
      legend.text = ggplot2::element_text(size = base_size - 0.5),
      legend.key.size = grid::unit(3.2, "mm"),
      legend.background = ggplot2::element_blank(),
      legend.box.background = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(size = base_size + 1, face = "bold", hjust = 0),
      plot.subtitle = ggplot2::element_text(size = base_size, hjust = 0),
      plot.margin = ggplot2::margin(4, 4, 4, 4, unit = "pt"),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(size = base_size, face = "bold")
    )
}

palette_okabe_ito <- c(
  blue = "#0072B2",
  vermillion = "#D55E00",
  green = "#009E73",
  purple = "#CC79A7",
  orange = "#E69F00",
  sky = "#56B4E9",
  yellow = "#F0E442",
  gray = "#7A7A7A"
)
```

## Standard ggplot Patterns

Use these compact patterns as defaults before customizing individual panels.

Enrichment dot plot:

```r
ggplot(enrich, aes(gene_ratio, reorder(term, gene_ratio),
                   size = gene_count, color = -log10(FDR))) +
  geom_point() +
  scale_color_gradientn(
    colors = c("#3C5488", "#4DBBD5", "#00A087", "#F39B7F", "#E64B35"),
    name = expression(-log[10]("FDR"))
  ) +
  scale_size_continuous(range = c(1.8, 4.6), name = "Genes") +
  labs(x = "Gene ratio", y = NULL) +
  theme_sci_minimal()
```

Faceted methylation context plot:

```r
ggplot(methylation, aes(stage, mC, group = 1, color = context)) +
  geom_errorbar(aes(ymin = mC - ci, ymax = mC + ci), width = 0.10) +
  geom_line(linewidth = 0.45) +
  geom_point(size = 1.0) +
  facet_grid(species ~ context) +
  scale_color_manual(values = c(CG = "#E64B35", CHG = "#4DBBD5", CHH = "#00A087")) +
  scale_y_continuous(labels = scales::percent) +
  theme_sci_minimal() +
  theme(panel.border = element_rect(color = "grey70", fill = NA, linewidth = 0.25))
```

Volcano or DMR scatter:

```r
ggplot(results, aes(effect, -log10(FDR), color = status)) +
  geom_point(size = 0.6) +
  geom_vline(xintercept = c(-threshold, threshold), linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c(Hyper = "#E64B35", Hypo = "#3C5488", Stable = "#9A9A9A")) +
  labs(x = "Effect size", y = expression(-log[10]("FDR"))) +
  theme_sci_minimal()
```

## Python Matplotlib Theme Template

Use for matplotlib/seaborn plots when R is not the project standard.

```python
import matplotlib as mpl

SCI_COLORS = {
    "blue": "#0072B2",
    "vermillion": "#D55E00",
    "green": "#009E73",
    "purple": "#CC79A7",
    "orange": "#E69F00",
    "sky": "#56B4E9",
    "yellow": "#F0E442",
    "gray": "#7A7A7A",
    "light_gray": "#D9D9D9",
}

def set_sci_minimal_theme():
    mpl.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
        "font.size": 7,
        "axes.labelsize": 7.5,
        "axes.titlesize": 8,
        "axes.linewidth": 0.6,
        "xtick.labelsize": 6.5,
        "ytick.labelsize": 6.5,
        "xtick.major.width": 0.5,
        "ytick.major.width": 0.5,
        "xtick.major.size": 2.5,
        "ytick.major.size": 2.5,
        "legend.fontsize": 6.5,
        "legend.title_fontsize": 7,
        "legend.frameon": False,
        "figure.dpi": 300,
        "savefig.dpi": 300,
        "savefig.bbox": "tight",
        "savefig.transparent": False,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": False,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    })
```

## Journal-Inspired Practical Notes

High-impact biological journals tend to favor:

- Dense but not crowded multi-panel figures.
- White backgrounds and restrained palettes.
- Clear panel order aligned to the Results narrative.
- Short labels, strong legends, and minimal decoration.
- Main figures that carry the biological message; supplementary figures that defend the analysis.
- Mechanistic schematics that distinguish data-supported relationships from proposed models.

Use published figures as references for clarity and restraint, not as templates to imitate exactly. The paper's own data structure should determine the final visual design.

## Preview Assets

All retained plotting examples are vector SVG files stored under
`assets/figure_previews/` and browsable from `figure_preview_gallery.html`.
Regenerate them with `scripts/generate_figure_preview_svgs.R`.

Keep this directory intentionally small: it should contain only the HTML gallery
and the SVG files referenced by that gallery. Do not keep PNG/PDF duplicates,
unreferenced historical previews, or old one-off preview scripts in this asset
directory.

Retained preview set:

- `figure_preview_gallery.html`: unified browser gallery with consistent card UI and image sizing.
- `palette_reference.svg`: publication color families for categorical biology, plant ecology, genomics tracks, transcriptomics, and proteomics.
- `theme_system_evidence.svg`: four-panel scientific figure rendered in the evidence-minimal theme.
- `theme_system_plant.svg`: the same four-panel structure rendered in the plant-natural theme.
- `theme_system_omics.svg`: the same four-panel structure rendered in the omics-compact theme.
- `theme_system_mechanism.svg`: the same four-panel structure rendered in the mechanism-clean theme.
- `biology_quantitative.svg`: bar, box, violin, and trajectory panels with raw data, intervals, and statistical marks.
- `biology_genomics.svg`: Manhattan signal, genome tracks, and synteny blocks.
- `biology_transcriptomics.svg`: expression heatmap, volcano plot, sample correlation, and MA-style signal view.
- `biology_proteomics.svg`: protein abundance, domain/lollipop, model effect, and enrichment views.
- `biology_functional.svg`: ranked terms, enrichment dot plot, and category-transition display.
- `biology_faceted_epigenomics.svg`: multi-species and CG/CHG/CHH faceted methylation, DMR volcano panels, genome tracks, and epigenetic legend grammar.
- `figure_quality_comparison.svg`: side-by-side weak versus recommended plotting choices for statistical summaries and heatmaps.
- `panel_assembly_balanced.svg`: balanced 2x2 publication-style panel assembly with external A/B/C/D labels.
