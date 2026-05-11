#!/usr/bin/env python3
"""Check figure preview assets and common publication-figure hygiene issues."""

from __future__ import annotations

import argparse
import re
import sys
from html.parser import HTMLParser
from pathlib import Path


SVG_UNSTABLE_PATTERNS = ("<filter", "<mask", "compositing-group")
VISIBLE_NA_PATTERNS = (
    re.compile(r">[ \t\r\n]*NA[ \t\r\n]*<"),
    re.compile(r">\s*N/A\s*<"),
)
WHITE_DATA_PATTERN = re.compile(
    r"scale_(?:fill|color|colour)_manual\s*\([^)]*(?:#FFFFFF|#FFF|\"white\"|'white')",
    re.IGNORECASE | re.DOTALL,
)


class ImageRefParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.srcs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() != "img":
            return
        attr_map = dict(attrs)
        src = attr_map.get("src")
        if src:
            self.srcs.append(src)


def is_ascii_path(path: Path) -> bool:
    try:
        str(path).encode("ascii")
    except UnicodeEncodeError:
        return False
    return True


def add_issue(items: list[str], path: Path, message: str, root: Path) -> None:
    try:
        label = path.relative_to(root)
    except ValueError:
        label = path
    items.append(f"{label}: {message}")


def check_zero_and_ascii(root: Path, errors: list[str]) -> None:
    for path in sorted(root.rglob("*")):
        if ".git" in path.parts:
            continue
        if not is_ascii_path(path.relative_to(root)):
            add_issue(errors, path, "path contains non-ASCII characters", root)
        if path.is_file() and path.stat().st_size == 0:
            add_issue(errors, path, "file is 0 bytes", root)


def check_preview_gallery(root: Path, preview_dir: Path, errors: list[str], warnings: list[str]) -> None:
    html = preview_dir / "figure_preview_gallery.html"
    if not html.exists():
        add_issue(errors, html, "preview gallery HTML is missing", root)
        return

    parser = ImageRefParser()
    parser.feed(html.read_text(encoding="utf-8"))
    refs = [src for src in parser.srcs if src]
    ref_set = set(refs)

    for src in refs:
        if src.startswith(("http://", "https://")):
            add_issue(warnings, html, f"external image reference is not self-contained: {src}", root)
            continue
        target = preview_dir / src
        if not target.exists():
            add_issue(errors, target, "HTML references a missing image", root)
        if not src.lower().endswith(".svg"):
            add_issue(errors, target, "preview gallery should reference SVG assets only", root)

    for path in sorted(preview_dir.iterdir()):
        if not path.is_file():
            continue
        if path.name == "figure_preview_gallery.html":
            continue
        if path.name not in ref_set:
            add_issue(errors, path, "preview asset is not referenced by the HTML gallery", root)
        if path.suffix.lower() != ".svg":
            add_issue(errors, path, "preview directory should not keep PNG/PDF/script leftovers", root)

    if len(refs) != len(ref_set):
        duplicates = sorted({src for src in refs if refs.count(src) > 1})
        add_issue(warnings, html, f"duplicate image references: {', '.join(duplicates)}", root)


def check_svg_content(root: Path, errors: list[str], warnings: list[str]) -> None:
    for path in sorted(root.rglob("*.svg")):
        if ".git" in path.parts:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in SVG_UNSTABLE_PATTERNS:
            if pattern in text:
                add_issue(errors, path, f"SVG contains browser-risky structure: {pattern}", root)
        for pattern in VISIBLE_NA_PATTERNS:
            if pattern.search(text):
                add_issue(warnings, path, "SVG appears to contain visible NA/N/A text", root)


def check_white_data_colors(root: Path, warnings: list[str]) -> None:
    for path in sorted(root.rglob("*")):
        if ".git" in path.parts or path.suffix.lower() not in {".r", ".rmd", ".md"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in WHITE_DATA_PATTERN.finditer(text):
            line_no = text[: match.start()].count("\n") + 1
            add_issue(
                warnings,
                path,
                f"manual data scale may use white as a data color near line {line_no}",
                root,
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        default=Path(__file__).resolve().parents[1],
        type=Path,
        help="Skill or figure directory to check. Defaults to this skill root.",
    )
    parser.add_argument(
        "--preview-dir",
        type=Path,
        default=None,
        help="Preview asset directory. Defaults to <root>/assets/figure_previews when present.",
    )
    parser.add_argument(
        "--strict-warnings",
        action="store_true",
        help="Exit nonzero when warnings are present.",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    preview_dir = args.preview_dir.resolve() if args.preview_dir else root / "assets" / "figure_previews"
    errors: list[str] = []
    warnings: list[str] = []

    if not root.exists():
        print(f"ERROR: root does not exist: {root}", file=sys.stderr)
        return 2

    check_zero_and_ascii(root, errors)
    if preview_dir.exists():
        check_preview_gallery(root, preview_dir, errors, warnings)
    check_svg_content(root, errors, warnings)
    check_white_data_colors(root, warnings)

    if warnings:
        print("Warnings:")
        for item in warnings:
            print(f"  - {item}")
    if errors:
        print("Errors:")
        for item in errors:
            print(f"  - {item}")
        return 1

    if args.strict_warnings and warnings:
        return 1

    print("Figure asset checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
