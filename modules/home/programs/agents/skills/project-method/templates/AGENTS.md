# AGENTS.md

Instructions for AI agents working in this repository. Read this file fully at the start of every
session.

<!-- Sections marked FILL are the project's own; the others are the method, kept in substance. -->

## Project

<!-- FILL: what the project is in one paragraph: what it does, for whom, in which language, on which
platforms, under which license. Its real state today, in one sentence. -->

It is developed primarily by AI agents; the owner sets its direction and validates architecture
decisions. Anyone arriving in the repository, at any point in its life, must be able to understand
all of it from the repository alone. Documentation is part of every deliverable, held to the same
standard as the code.

## Read before working

1. `docs/PLAN.md`: the current stage, its milestones and their status. The source of truth for what
   to do now.
2. `docs/ROADMAP.md`: direction, stage order, exit criteria. An overview, not a commitment.
3. `docs/ARCHITECTURE.md`: the parts of the code, their roles and their dependencies.
4. `docs/adr/`: decisions already made. Do not decide them again.

You have no memory of previous sessions. These files are the project's memory: what is not written
there, the next session will not know.

## Scope

- Work only on the stage and milestone marked as current in `docs/PLAN.md`.
- Do not start later stages, and do not add abstractions that prepare for them.
- If a task needs something out of scope, stop and say so.

The roadmap sets direction and order; it does not say what will be built, nor how. Build something
because the current milestone needs it, never because the roadmap mentions it. When experience
contradicts the roadmap, propose a change; once accepted, record it in an ADR.

## Environment and commands

<!-- FILL: the development environment (the Nix shell, toolchains, services needed) and every
command an agent needs: build, test, lint, format, documentation, run the program, run it on a test
profile that never touches the owner's data, measure. Keep this section up to date when commands
are added. -->

```sh
scripts/check.sh    # every check of the definition of done; what CI runs
```

`scripts/check.sh` is what CI runs. Run it before reporting a milestone done.

<!-- FILL: how an agent runs the program without touching the owner's real data (a test profile, a
data directory of its own), and what it must never do on its own (spend money, act on real
accounts, delete user files...). -->

## Definition of done

A milestone is done only when all of the following hold:

- `scripts/check.sh` passes.
- The program was actually run and behaved as expected.
- New behaviour is covered by tests where a test is practical.
- `docs/PLAN.md` reflects the new status.
- Every document affected by the change is updated, and was reread as a newcomer would read it.
- Any decision taken is recorded as an ADR.

Never report that something works without having verified it. If you could not verify, say exactly
what was not verified and why.

## Architecture rules

<!-- FILL: the rules the structure depends on: which part may depend on which, what stays out of
the interface layer, what must run without a window or a network, where platform code lives. -->

## Rules the code depends on

<!-- FILL: secrets and privacy, data safety (what is never deleted or overwritten), honesty towards
third-party services, platform quirks: whatever a newcomer could break without knowing. -->

## Code rules

- No abstraction without a second concrete use. No trait, generic or layer added "just in case".
- Do not reimplement what the standard library provides without a measurement that justifies it.
- Every new dependency needs a justification: why, which alternative was considered, its license.
  Ask the owner before adding one.
- Every `unsafe` block carries a `// SAFETY:` comment explaining why it is sound.
- Comments explain why, not what. No commented-out code.
- Follow the conventions that ADRs set. If no ADR covers a case, propose one instead of deciding
  silently.

## Consistency rules

- Before writing a helper, type or pattern, search the code for an existing one. Reuse or extend it.
- One way to do a given thing. If you find two, unify them or report it.
- Prefer less code. Delete dead code, unused parameters and unused features.
- Keep changes local to the milestone. Unrelated cleanup goes in a separate commit, or in a note in
  `docs/PLAN.md`.
- If the code has drifted from `docs/ARCHITECTURE.md` or an ADR, report it. Do not silently work
  around it.

## Documentation

### Standard

The reader is a competent developer who has never seen this project. From the repository alone,
they must be able to understand what every part does and why it is built that way, then build, test
and change it.

- Documentation describes the code as it is now, not as it is intended to be. Wrong documentation
  is worse than missing documentation.
- No reference to past sessions or conversations the reader cannot see; every term the project
  coins is defined where it first appears and in `docs/glossary.md`.
- State limits and known debt plainly. Do not present a partial feature as complete.
- Every public item has documentation that says what it does, its invariants, its errors and its
  panics.
- A change that leaves a document wrong is not finished.

### One home per fact

A fact written in two places drifts. Each kind of fact has one home, and other documents link to it:

- **The code's documentation**: what an item does, its contracts, its limits and their figures.
- **`docs/ARCHITECTURE.md`**: the flows across the parts, without the figures the code's
  documentation holds.
- **ADRs**: why a decision was taken and what was rejected. Only their status changes afterwards.
- **`docs/PLAN.md`**: status and known debt, linking to where the facts live.
- **`CHANGELOG.md`**: what changed for users, once, when it changes.

| File | Content | Update when |
|---|---|---|
| `README.md` | What the project is, its real state, how to build and run it | State or entry points change |
| `docs/ROADMAP.md` | Direction, stage order, exit criteria | A stage is reshaped, merged or dropped (with an ADR) |
| `docs/PLAN.md` | Current stage, milestones, status, known debt | Every milestone |
| `docs/ARCHITECTURE.md` | Parts, responsibilities, dependencies, main flows | Structure or a flow changes |
| `docs/adr/NNNN-title.md` | Context, decision, alternatives rejected, consequences | Each decision |
| `docs/adr/README.md` | The index of the ADRs and their statuses | An ADR is added or its status changes |
| `docs/glossary.md` | Terms the project defines | A term is coined or changes meaning |
| `CHANGELOG.md` | Notable changes, per release | A change users would notice; a release |

## Commits

- One logical change per commit, small enough to review.
- Subject in the imperative, in English. The body explains why when it is not obvious.
- Do not commit code that fails the checks.

## When to stop and ask

Stop and ask the owner before proceeding when:

- A decision affects the architecture and no ADR covers it.
- You want to add a dependency.
- The request contradicts `docs/ROADMAP.md` or an ADR.
- The plan turns out to be wrong, or a milestone is larger than expected.
- You are about to delete or rewrite a significant part of the code.

Propose the options with their trade-offs, in plain terms, and a recommendation for the long term.
Put decisions one at a time. Do not work around a problem to keep going.

## Reporting

At the end of each milestone, report:

- What was done.
- Notable design choices, why, and which alternatives were rejected.
- What deserves to be read first.
- Shortcuts taken and debt introduced.
- The next step, on the owner's go.

A reviewing agent checks the milestone against this file and the ADRs before it is reported done.

## Working with several agents

- Each agent works on one milestone at a time, as `docs/PLAN.md` assigns it.
- Shared files (`docs/PLAN.md`, `docs/ARCHITECTURE.md`, the build manifests) are edited by one agent
  at a time.
- Commit your own files by their paths, never with `git add -A`, so as not to take another agent's.

## Language

- Everything in the repository is in English: code, comments, commits, documentation.
- Talk to the owner in French.
