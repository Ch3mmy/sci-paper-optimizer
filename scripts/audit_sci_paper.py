#!/usr/bin/env python3
"""Generic manuscript triage for SCI paper drafts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


SECTION_PATTERNS = {
    "abstract_or_summary": re.compile(r"^#{1,3}\s*(abstract|summary)\b", re.IGNORECASE),
    "introduction": re.compile(r"^#{1,3}\s*introduction\b", re.IGNORECASE),
    "methods": re.compile(r"^#{1,3}\s*(materials and methods|methods|methodology)\b", re.IGNORECASE),
    "results": re.compile(r"^#{1,3}\s*results\b", re.IGNORECASE),
    "discussion": re.compile(r"^#{1,3}\s*discussion\b", re.IGNORECASE),
    "data_availability": re.compile(r"^#{1,3}\s*data availability\b", re.IGNORECASE),
}

RISK_PATTERNS = [
    (
        "proof_language",
        re.compile(r"\b(proves?|proved|proof that|undeniably|conclusively)\b", re.IGNORECASE),
        "Proof-style language usually needs stronger evidence or softer wording.",
    ),
    (
        "causal_overclaim",
        re.compile(r"\b(demonstrates?|shows?)\s+that\b.{0,80}\b(causes?|drives?|determines?)\b", re.IGNORECASE),
        "Check whether the design justifies causal wording.",
    ),
    (
        "inflated_mechanism",
        re.compile(r"\b(master regulator|key mechanism|central mechanism|definitive mechanism)\b", re.IGNORECASE),
        "Mechanistic labels should be reserved for well-supported causal evidence.",
    ),
    (
        "unqualified_prediction",
        re.compile(
            r"\b(confirmed|validated|proved|definitive)\s+(prediction|candidate|putative)\b"
            r"|"
            r"\b(predicted|putative|candidate)\b.{0,40}\b(is|are|was|were)\b.{0,20}\b(confirmed|validated|proved|definitive)\b",
            re.IGNORECASE,
        ),
        "Do not mix candidate/predicted status with confirmed language unless validation is described.",
    ),
]


@dataclass
class Finding:
    severity: str
    code: str
    message: str
    path: str | None = None
    line: int | None = None


def add(findings: list[Finding], severity: str, code: str, message: str, path: Path | None = None, line: int | None = None) -> None:
    findings.append(Finding(severity, code, message, str(path) if path else None, line))


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def audit_manuscript(path: Path, findings: list[Finding]) -> None:
    if not path.exists():
        add(findings, "ERROR", "missing_manuscript", "Manuscript file does not exist.", path)
        return

    text = read_text(path)
    lines = text.splitlines()

    for name, pattern in SECTION_PATTERNS.items():
        if not any(pattern.search(line) for line in lines):
            add(findings, "WARN", "missing_core_section", f"Could not find section: {name}", path)

    placeholder_re = re.compile(r"\b(TODO|TBD|PLACEHOLDER|XXX)\b|\[[A-Z][A-Z0-9 _/-]{3,}\]", re.IGNORECASE)
    fig_re = re.compile(r"\bFig(?:ure)?\.\s*([0-9]+|S[0-9]+)\b", re.IGNORECASE)
    table_re = re.compile(r"\bTable\s*([0-9]+|S[0-9]+)\b", re.IGNORECASE)

    figure_refs: list[str] = []
    table_refs: list[str] = []

    for line_no, line in enumerate(lines, start=1):
        if placeholder_re.search(line):
            add(findings, "WARN", "placeholder", "Placeholder or bracketed missing field remains.", path, line_no)
        for code, pattern, message in RISK_PATTERNS:
            if pattern.search(line):
                if code == "unqualified_prediction" and re.search(r"\b(no|not|rather than)\s+confirmed\b", line, re.IGNORECASE):
                    continue
                add(findings, "WARN", code, message, path, line_no)
        figure_refs.extend(match.group(1).upper() for match in fig_re.finditer(line))
        table_refs.extend(match.group(1).upper() for match in table_re.finditer(line))

    if len(set(figure_refs)) > 8:
        add(findings, "INFO", "many_main_or_supp_figure_refs", f"Found {len(set(figure_refs))} distinct figure references; check whether the main story is overpacked.", path)
    if len(set(table_refs)) > 6:
        add(findings, "INFO", "many_table_refs", f"Found {len(set(table_refs))} distinct table references; check whether large tables should move to supplement.", path)

    abstract_like = _extract_section(lines, SECTION_PATTERNS["abstract_or_summary"])
    if abstract_like:
        risky = ["may", "could", "suggest", "candidate", "putative"]
        if not any(word in abstract_like.lower() for word in risky):
            add(findings, "INFO", "abstract_uncertainty_check", "Abstract/Summary contains little uncertainty language; check whether claims are calibrated.", path)


def _extract_section(lines: list[str], start_pattern: re.Pattern[str]) -> str:
    start = None
    for idx, line in enumerate(lines):
        if start_pattern.search(line):
            start = idx
            break
    if start is None:
        return ""
    body = []
    for line in lines[start + 1 :]:
        if re.match(r"^#{1,3}\s+\S+", line):
            break
        body.append(line)
    return "\n".join(body)


def audit_paths(root: Path, findings: list[Finding]) -> None:
    if not root.exists():
        add(findings, "ERROR", "missing_root", "Project root does not exist.", root)
        return
    for path in root.rglob("*"):
        if path.is_file() and path.stat().st_size == 0:
            add(findings, "WARN", "zero_byte_file", "Zero-byte file found; verify whether this is expected.", path)
        if any(ord(ch) > 126 or ord(ch) < 32 for ch in path.name):
            add(findings, "INFO", "non_ascii_path", "Non-ASCII or non-printable path name found.", path)


def print_text(findings: list[Finding]) -> None:
    if not findings:
        print("No audit findings.")
        return
    for item in findings:
        location = ""
        if item.path:
            location = f" [{item.path}"
            if item.line is not None:
                location += f":{item.line}"
            location += "]"
        print(f"{item.severity} {item.code}{location}: {item.message}")
    counts = {level: sum(1 for item in findings if item.severity == level) for level in ["ERROR", "WARN", "INFO"]}
    print(f"\nSummary: {counts['ERROR']} error(s), {counts['WARN']} warning(s), {counts['INFO']} info item(s)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manuscript", required=True, help="Markdown or text manuscript to audit")
    parser.add_argument("--project-root", help="Optional root to scan for zero-byte and non-ASCII paths")
    parser.add_argument("--json", action="store_true", help="Emit JSON findings")
    args = parser.parse_args(argv)

    findings: list[Finding] = []
    audit_manuscript(Path(args.manuscript).expanduser().resolve(), findings)
    if args.project_root:
        audit_paths(Path(args.project_root).expanduser().resolve(), findings)

    if args.json:
        print(json.dumps([asdict(item) for item in findings], ensure_ascii=False, indent=2))
    else:
        print_text(findings)

    return 1 if any(item.severity == "ERROR" for item in findings) else 0


if __name__ == "__main__":
    sys.exit(main())
