# Design discussions

This document records structural choices, alternatives, rationale, and
status. It does not duplicate behavioral specifications. An open
decision may be indexed as a concern when it blocks work or creates
material risk.

| Decision | Status | Date |
|---|---|---|
| Analysis backend: Libadalang vs lightweight reader | Discussing | 2026-10-29 |
| HAC declaration mechanism: `with Import => True` placement (nested vs package spec) | Discussing | 2026-10-29 |
| Boolean mapping route: generic enum vs Integer | Discussing | 2026-10-29 |
| Manifest design (generated artefacts policy): check-in policy, generation during builds, source hashes, version coupling, JSON format | Discussing | 2026-10-29 |

Statuses: Discussing | Accepted | Rejected | Superseded.

## Template for a new discussion

Copy this block for each new discussion, as a `###` section.

### <title>

Status: Discussing
Date: YYYY-MM-DD
Related: <proposal, concern, issue, or feature>

## Context

<Forces and constraints that make a decision necessary.>

## Options considered

### Option A

- Benefits: ...
- Costs and risks: ...

### Option B

- Benefits: ...
- Costs and risks: ...

## Decision

<Leave open while Discussing.>

## Rationale

<Why this option was selected.>

## Consequences

- ...
