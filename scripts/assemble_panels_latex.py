#!/usr/bin/env python3
"""Assemble figure panels with external labels using LaTeX.

Example:
  python assemble_panels_latex.py \
    --panels A=panel1.pdf B=panel2.pdf C=panel3.pdf D=panel4.pdf \
    --layout 2x2 --out Figure1_composite.pdf

Panel labels are added at assembly time, so source panels remain label-free and
can be reordered without editing the panel files.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def latex_escape(text: str) -> str:
    repl = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    return "".join(repl.get(ch, ch) for ch in text)


def parse_layout(raw: str) -> tuple[int, int]:
    if "x" not in raw.lower():
        raise ValueError("Layout must look like 2x2 or 3x2")
    rows, cols = raw.lower().split("x", 1)
    rows_i, cols_i = int(rows), int(cols)
    if rows_i < 1 or cols_i < 1:
        raise ValueError("Layout rows and columns must be positive")
    return rows_i, cols_i


def parse_panel_arg(raw: str) -> tuple[str, Path]:
    if "=" not in raw:
        raise ValueError(f"Panel must look like A=path/to/panel.pdf: {raw}")
    label, path = raw.split("=", 1)
    label = label.strip()
    path_obj = Path(path).expanduser().resolve()
    if not label:
        raise ValueError(f"Empty panel label in {raw}")
    if not path_obj.exists():
        raise FileNotFoundError(f"Panel file does not exist: {path_obj}")
    return label, path_obj


def load_config(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def panels_from_args(args: argparse.Namespace) -> list[tuple[str, Path]]:
    if args.config:
        cfg = load_config(Path(args.config).expanduser().resolve())
        panels = [(str(item["label"]), Path(item["path"]).expanduser().resolve()) for item in cfg["panels"]]
        for _, path in panels:
            if not path.exists():
                raise FileNotFoundError(f"Panel file does not exist: {path}")
        for key in [
            "layout",
            "width_mm",
            "gap_mm",
            "row_gap_mm",
            "label_size",
            "label_offset_x_mm",
            "label_offset_y_mm",
            "caption_space_mm",
        ]:
            if key in cfg and getattr(args, key) == parser.get_default(key):
                setattr(args, key, cfg[key])
        return panels
    return [parse_panel_arg(raw) for raw in args.panels]


def build_tex(
    panels: list[tuple[str, Path]],
    rows: int,
    cols: int,
    width_mm: float,
    gap_mm: float,
    row_gap_mm: float,
    label_size: float,
    label_offset_x_mm: float,
    label_offset_y_mm: float,
    caption_space_mm: float,
) -> str:
    cell_w_mm = (width_mm - gap_mm * (cols - 1)) / cols
    if cell_w_mm <= 0:
        raise ValueError("Computed panel cell width is not positive; reduce columns or gap")
    needed = rows * cols
    if len(panels) > needed:
        raise ValueError(f"{len(panels)} panels do not fit in {rows}x{cols} layout")

    row_heights_mm: list[float] = []
    padded = panels + [("", None)] * (needed - len(panels))
    for r in range(rows):
        heights = []
        for c in range(cols):
            _, path = padded[r * cols + c]
            if path is None:
                heights.append(caption_space_mm)
            else:
                w_pt, h_pt = read_pdf_page_size_pt(path)
                heights.append(caption_space_mm + cell_w_mm * h_pt / w_pt)
        row_heights_mm.append(max(heights))
    paper_height_mm = sum(row_heights_mm) + row_gap_mm * (rows - 1)

    lines = [
        r"\documentclass{article}",
        r"\usepackage{graphicx}",
        r"\usepackage{xcolor}",
        r"\usepackage{array}",
        rf"\usepackage[paperwidth={width_mm:.3f}mm,paperheight={paper_height_mm:.3f}mm,margin=0pt]{{geometry}}",
        r"\pagestyle{empty}",
        r"\definecolor{PanelText}{HTML}{222222}",
        r"\begin{document}",
        r"\noindent",
        r"\setlength{\tabcolsep}{0pt}",
        r"\renewcommand{\arraystretch}{1}",
        r"\begin{tabular}{@{}" + ("c" * cols) + r"@{}}",
    ]

    for r in range(rows):
        row_cells = []
        for c in range(cols):
            idx = r * cols + c
            label, path = padded[idx]
            if path is None:
                cell = rf"\begin{{minipage}}[t]{{{cell_w_mm:.3f}mm}}\vspace{{{caption_space_mm:.3f}mm}}\end{{minipage}}"
            else:
                label_tex = latex_escape(label)
                path_tex = str(path).replace("\\", "/")
                cell = (
                    rf"\begin{{minipage}}[t]{{{cell_w_mm:.3f}mm}}"
                    rf"\makebox[0pt][l]{{\hspace*{{{label_offset_x_mm:.3f}mm}}"
                    rf"\raisebox{{{label_offset_y_mm:.3f}mm}}{{\fontsize{{{label_size:.3f}}}{{{label_size * 1.1:.3f}}}\selectfont\bfseries\color{{PanelText}} {label_tex}}}}}"
                    rf"\vspace*{{{caption_space_mm:.3f}mm}}"
                    rf"\includegraphics[width=\linewidth]{{{path_tex}}}"
                    rf"\end{{minipage}}"
                )
            row_cells.append(cell)
            if c < cols - 1:
                row_cells.append(rf"\hspace{{{gap_mm:.3f}mm}}")
        lines.append("".join(row_cells) + (r"\\[" + f"{row_gap_mm:.3f}mm" + "]" if r < rows - 1 else ""))
    lines.extend([r"\end{tabular}", r"\end{document}"])
    return "\n".join(lines) + "\n"


def read_pdf_page_size_pt(path: Path) -> tuple[float, float]:
    if path.suffix.lower() != ".pdf":
        raise ValueError(f"LaTeX vector assembly currently requires PDF panels. Use the R magick route for raster/mixed panels: {path}")
    if shutil.which("pdfinfo") is None:
        raise RuntimeError("pdfinfo was not found on PATH")
    proc = subprocess.run(["pdfinfo", str(path)], check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in proc.stdout.splitlines():
        if line.startswith("Page size:"):
            parts = line.replace("Page size:", "").strip().split()
            return float(parts[0]), float(parts[2])
    raise RuntimeError(f"Could not read Page size from pdfinfo output for {path}")


def compile_latex(tex_path: Path, engine: str) -> Path:
    if shutil.which(engine) is None:
        raise RuntimeError(f"{engine} was not found on PATH")
    cmd = [engine, "-interaction=nonstopmode", "-halt-on-error", tex_path.name]
    try:
        subprocess.run(cmd, cwd=tex_path.parent, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    except subprocess.CalledProcessError as exc:
        tail = "\n".join((exc.stdout or "").splitlines()[-40:])
        raise RuntimeError(f"LaTeX failed while compiling {tex_path}:\n{tail}") from exc
    pdf = tex_path.with_suffix(".pdf")
    if not pdf.exists() or pdf.stat().st_size == 0:
        raise RuntimeError(f"LaTeX did not produce a nonempty PDF: {pdf}")
    return pdf


def main(argv: list[str] | None = None) -> int:
    global parser
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--panels", nargs="*", default=[], help="Panel entries such as A=panel1.pdf B=panel2.pdf")
    parser.add_argument("--config", help="Optional JSON config with panels and layout options")
    parser.add_argument("--layout", default="2x2", help="Rows x columns, e.g. 2x2 or 3x2")
    parser.add_argument("--out", required=True, help="Output composite PDF")
    parser.add_argument("--width-mm", type=float, default=178.0, help="Total figure width in mm")
    parser.add_argument("--gap-mm", type=float, default=4.0, help="Horizontal gap between panels in mm")
    parser.add_argument("--row-gap-mm", type=float, default=4.0, help="Vertical gap between panel rows in mm")
    parser.add_argument("--label-size", type=float, default=10.0, help="Panel label font size in pt")
    parser.add_argument("--label-offset-x-mm", type=float, default=0.0, help="Label x offset relative to panel left edge")
    parser.add_argument("--label-offset-y-mm", type=float, default=1.2, help="Label y offset above the panel image")
    parser.add_argument("--caption-space-mm", type=float, default=3.0, help="Vertical space reserved for external label above each panel")
    parser.add_argument("--engine", default="pdflatex", choices=["pdflatex", "xelatex", "lualatex"], help="LaTeX engine")
    parser.add_argument("--keep-tex", action="store_true", help="Keep generated .tex next to output")
    args = parser.parse_args(argv)

    if not args.config and not args.panels:
        parser.error("Provide --panels or --config")

    panels = panels_from_args(args)
    rows, cols = parse_layout(args.layout)
    tex = build_tex(
        panels,
        rows,
        cols,
        args.width_mm,
        args.gap_mm,
        args.row_gap_mm,
        args.label_size,
        args.label_offset_x_mm,
        args.label_offset_y_mm,
        args.caption_space_mm,
    )

    out_pdf = Path(args.out).expanduser().resolve()
    out_pdf.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="assemble_panels_") as tmp_raw:
        tmp = Path(tmp_raw)
        tex_path = tmp / "composite.tex"
        tex_path.write_text(tex, encoding="utf-8")
        pdf = compile_latex(tex_path, args.engine)
        shutil.copy2(pdf, out_pdf)
        if args.keep_tex:
            out_tex = out_pdf.with_suffix(".tex")
            out_tex.write_text(tex, encoding="utf-8")
    print(f"Wrote {out_pdf} ({out_pdf.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
