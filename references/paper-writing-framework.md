# Paper Writing Framework

Use this reference to plan, write, or revise an SCI manuscript in any field.

## Manuscript Strategy

Start by reducing the project to four elements:

1. Problem: what scientific uncertainty or gap matters?
2. System: why this dataset, organism, cohort, model, experiment, or method can answer it?
3. Evidence chain: what result blocks progressively resolve the problem?
4. Contribution: what can the field believe or use after reading the paper?

If any element is vague, fix the framing before polishing sentences.

## Story Architecture

Build the paper around a small number of evidence blocks. A typical structure is:

- Context and unresolved question.
- Study design and validation of the system.
- Primary result that establishes the main phenomenon.
- Mechanistic, comparative, or explanatory result.
- Robustness, controls, or prioritization.
- Integrated model, implications, and limits.

Do not let the manuscript become a chronological analysis log. Reorder results so that each subsection answers a question raised by the previous one.

## Section Standards

Title:

- Name the biological, clinical, computational, or methodological contribution.
- Avoid unsupported causal claims or excessive breadth.

Abstract or Summary:

- State the gap, approach, key quantitative findings, and restrained conclusion.
- Use numbers only when they are stable and sourced.
- Do not introduce claims absent from Results.

Introduction:

- Build tension from field problem to specific unknown.
- Explain why current knowledge is insufficient.
- End with the study design and the questions answered, not a full results list.

Results:

- Use subsection headings that express scientific messages.
- Begin each subsection with the question or rationale.
- Present methods only enough to orient the result; keep procedural detail in Methods.
- End each subsection with what the result supports and what it does not prove.

Discussion:

- Start from the main answer, not a recap of every result.
- Compare with prior literature.
- Separate established findings, candidate mechanisms, and hypotheses.
- State limitations plainly and connect them to future validation.

Methods:

- Include data sources, sample design, preprocessing, inclusion/exclusion criteria, parameters, software versions when relevant, statistical tests, effect sizes, uncertainty estimates, and multiple-testing correction.
- Provide enough information for a reviewer to reproduce or judge the analysis.

Data and Code Availability:

- Do not invent accessions or DOIs.
- Mark missing repositories or author-supplied fields clearly.

## Claim Discipline

Use claim wording that matches evidence strength:

| Evidence | Safer wording |
| --- | --- |
| Direct experimental test | shows, supports, indicates, confirms within this assay |
| Statistical result | enriched, depleted, associated with, correlated with, differs by |
| Multi-omics or observational pattern | consistent with, linked to, coupled with, suggests |
| Computational prediction | candidate, putative, predicted, prioritized |
| Model or interpretation | supports a model, raises the hypothesis, proposes |
| Future experiment | testable by, requires validation, should be evaluated by |

Avoid proof-style language unless the design truly proves causality. Words that often need checking include: `prove`, `demonstrate that X causes`, `drives`, `determines`, `master regulator`, `key mechanism`, `novel` without context, and `first` without literature verification.

## Evidence Traceability

For each important claim, record:

- Claim text.
- Figure/table or result file.
- Analysis script or experimental source.
- Statistical test and threshold.
- Caveat or boundary condition.

If a claim cannot be traced, downgrade it, move it to speculation, or remove it.

## Optimization Passes

Run manuscript revision in this order:

1. Logic pass: Does the paper answer one coherent question?
2. Evidence pass: Is every major claim supported by a specific result?
3. Causality pass: Are causal verbs justified by design?
4. Methods pass: Can reviewers evaluate inputs, thresholds, models, and controls?
5. Figure pass: Can the paper's argument be understood from figures and legends?
6. Language pass: Remove repetition, vague intensifiers, and inflated claims.

Do not start with sentence polishing when the argument or evidence chain is unstable.
