---
name: project-method
description: The owner's method for a project that agents develop while the owner sets its direction, taken from SlimeEngine, where it works best. The rules file (AGENTS.md); the project's memory in the repository (PLAN, ROADMAP, ARCHITECTURE, ADRs, glossary, CHANGELOG); small milestones that can be verified; one check command that CI runs; decisions put to the owner as options. Use it when starting a new project, when bringing an existing one under the method (Music, Slatty or others), or when the owner asks for strict rules and a clear direction "as in SlimeEngine".
---

# The project method

Agents remember nothing from one session to the next. A project they develop well keeps its memory
and its rules in the repository, where every session reads them first. SlimeEngine
(`~/Projects/SlimeEngine`) is the reference: when in doubt, read how its `AGENTS.md`, `docs/PLAN.md`,
`docs/ROADMAP.md` and `docs/adr/` do it.

The templates beside this file are plain files, so that agents other than Claude can read them too:
`templates/` mirrors a repository's layout.

## What a project holds

Each kind of fact has one home. Other documents link to it instead of copying it, because a fact
written twice drifts.

| File | What it holds |
|---|---|
| `AGENTS.md` | The rules for agents: what the project is, what to read first, scope, commands, definition of done, code and documentation rules, when to stop and ask, reporting. Tracked in the repository. `CLAUDE.md` holds only `@AGENTS.md` and stays local. |
| `README.md` | What the project is, its real state, how to build and run it, where to read next |
| `docs/ROADMAP.md` | Direction: stages in order, each with a goal and an exit criterion. The owner sets it. |
| `docs/PLAN.md` | The current stage: its milestones, their status, how each is checked, the known debt |
| `docs/ARCHITECTURE.md` | The parts of the code, their roles, what depends on what, the main flows, where to start reading |
| `docs/adr/NNNN-title.md` | One decision each: context, decision, alternatives rejected, consequences. Only the status changes afterwards. |
| `docs/adr/README.md` | The index of the ADRs and their statuses |
| `docs/glossary.md` | The terms the project coins |
| `CHANGELOG.md` | What changed for users, per release |
| `scripts/check.sh` | Every automated check of the definition of done, in one command |
| `.github/workflows/ci.yml` | CI, which runs `scripts/check.sh` unchanged on every push and pull request |

API contracts live in the code's documentation (rustdoc for Rust), not in these files.

## Bringing a project under the method

Done by the project's own session, which knows its code. Nothing is committed before the owner has
seen the ROADMAP and the list of ADRs.

1. **Inventory.** Read the code and every document that exists. List what the table above asks and
   what the project already has. Keep every good rule that already exists: knowledge must not be
   lost in the move.
2. **`AGENTS.md`**, from `templates/AGENTS.md`. Keep the method's sections in substance; fill the
   project's: what it is, commands, its architecture rules, the rules its code depends on (secrets,
   data safety, platform quirks), its known pitfalls.
3. **`docs/ARCHITECTURE.md`**, the code as it is now, not as intended.
4. **ADRs for the decisions already taken**, the ones a newcomer would otherwise question or undo:
   frameworks, platforms, data formats, security choices, what was tried and abandoned. Each with its
   context, the decision, the alternatives rejected and the consequences; status `Accepted`; the
   date it was taken when known. A table of decisions that already exists becomes the source of
   these ADRs.
5. **`docs/ROADMAP.md`**, drafted from what exists and what the owner has said, marked as a
   proposal: stages in order, each with its goal and its exit criterion. The owner decides it.
6. **`docs/PLAN.md`**: the current stage, its milestones (goal, what it delivers, done when, how to
   test), a status table, the known debt.
7. **`scripts/check.sh` and CI**: build, tests, lints with warnings as errors, formatting, the
   documentation's build and links, the dependency checks the project uses. CI runs the script
   unchanged, on every platform the project ships on.
8. **`docs/glossary.md` and `CHANGELOG.md`**, if missing.
9. **Show the owner**, in French: the ROADMAP proposed, the list of ADRs, what changed in the rules.
   Commit only after the owner's go, one logical change per commit.

## Working under the method

- **At the start of every session**, read `AGENTS.md`, `docs/PLAN.md`, `docs/ROADMAP.md` and the
  index of the ADRs. Do not decide again what an ADR decided.
- **Scope**: only the current milestone of `docs/PLAN.md`. A milestone larger than expected is
  split, with the owner's agreement. Nothing is built "because the roadmap mentions it".
- **Done** means: the checks pass, the program was run and behaved as expected, new behaviour is
  tested where practical, `docs/PLAN.md` says so, every document affected was updated and reread as
  a newcomer would, and any decision taken is an ADR. Never report as working what was not verified;
  say exactly what was not.
- **Decisions belong to the owner.** Put them one at a time: the options, their pros and cons in
  plain terms, a recommendation for the long term, not the cheapest now. The owner chooses; record
  it as an ADR.
- **Stop and ask** before a decision no ADR covers, a new dependency, a request that contradicts the
  ROADMAP or an ADR, a plan that turns out wrong, or deleting or rewriting a significant part of the
  code.
- **Before reporting a milestone done**, a reviewing agent checks it against `AGENTS.md` and the
  ADRs.
- **Report at the end of each milestone, in French**: what was done; the notable choices, why, and
  the alternatives rejected; what to read first; shortcuts taken and debt; then "Prochaine étape …
  sur ton feu vert".
- **Measure rather than guess**: performance claims come with figures, kept in the repository.

The owner's standing rules (privileges, git identity, no mention of AI in commits, no personal data,
committing, pushing and opening issues without asking in the owner's repositories) are in the
global rules that every agent reads, kept in `~/NixOS/modules/home/programs/agents/AGENTS.md`;
they are not copied here.
