# AGENTS.md

Rules for AI agents working in this repository. Read this file fully at the start of every session.

<!-- Sections marked FILL are the project's own; the others are the method. Keep the whole file
under about 1,500 words, in short sentences: every session reads all of it. -->

## Project

<!-- FILL: what the project is, in a few sentences: what it does, for whom, in which language, on
which platforms, under which license. Its real state today. -->

Agents develop it; the owner sets its direction and validates its decisions. Anyone must be able to
understand it from the repository alone. Documentation is part of every deliverable.

## Read before working

- `docs/PLAN.md`, its *Current* section and the current milestone: what to do now.
- When planning, or when the task touches a decision: `docs/ROADMAP.md` (direction, stages, the
  quality bar), `docs/ARCHITECTURE.md`, and `docs/adr/`, the decisions already made.

You remember nothing from earlier sessions. What is not written in these files is lost.

## Scope

- Work on the current milestone of `docs/PLAN.md`, or on what the owner asks. A request that changes
  the plan is written into the PLAN.
- Do not start later stages, nor prepare abstractions for them.
- When experience contradicts the roadmap, propose a change; once accepted, record it in an ADR.

## Commands

<!-- FILL: one line per command an agent needs: enter the environment, build, test, run the
program on a test profile that never touches the owner's data. Their detail lives in
CONTRIBUTING.md. -->

```sh
scripts/check.sh    # every check of the definition of done; what CI runs
```

<!-- FILL: what an agent never does on its own here (real accounts, payments, the user's files). -->

## Definition of done

- `scripts/check.sh` passes.
- The program was run and behaved as expected.
- New behaviour is tested where a test is practical.
- The budgets the milestone touches are measured and met; the figures go to
  `docs/measurements.md`.
- `docs/PLAN.md` gives the new status.
- Every document the change affects is updated and reread as a newcomer would.
- Every decision a newcomer would question is an ADR.

Never report as working what was not verified. Say exactly what was not, and why.

## Architecture rules

<!-- FILL: which part may depend on which; what must run without a window or a network; where
platform code lives. -->

## Rules the code depends on

<!-- FILL: secrets and privacy, data safety, honesty towards third-party services, platform quirks:
whatever a newcomer could break without knowing. -->

## Code rules

- No abstraction without a second concrete use.
- No reimplementation of the standard library without a measurement.
- A new dependency needs a reason, an alternative weighed and a license checked; ask the owner.
- Every `unsafe` block has a `// SAFETY:` comment.
- Comments say why, not what. No commented-out code.
- Search for an existing helper before writing one. One way to do a thing.
- Delete dead code and unused parameters.
- Report drift from `docs/ARCHITECTURE.md` or an ADR; do not work around it.

## Documentation

- It describes the code as it is now. Wrong documentation is worse than none.
- No reference to conversations the reader cannot see. Coined terms go in `docs/glossary.md`.
- Limits and debt are stated plainly.
- Each fact has one home; other documents link to it:
  - the code's documentation: contracts, limits, figures;
  - `docs/ARCHITECTURE.md`: flows across parts;
  - ADRs: why a decision was taken, what was rejected; only their status changes later;
  - `docs/PLAN.md`: status and known debt;
  - `CHANGELOG.md`: what changed for users.
- A change that leaves a document wrong is not finished.

## Commits

- One logical change per commit, in English, its subject in the imperative.
- Never commit code that fails the checks.

## When to stop and ask

Before a decision no ADR covers, a new dependency, a request against the roadmap or an ADR, a plan
that turns out wrong, or deleting or rewriting a large part of the code. Give the options, their
trade-offs in plain terms and a recommendation for the long term, one decision at a time.

## Reporting

At the end of each milestone, after a reviewing agent on the strongest model has checked it against
this file, the ADRs and the quality bar, report: what was done; the choices, why, and the
alternatives rejected; what to read first; the figures measured; shortcuts and debt; the next step,
on the owner's go. The next milestone starts in a new session, unless the owner says to continue.

## Working with several agents

- One milestone per agent, as `docs/PLAN.md` assigns it.
- Shared files (`docs/PLAN.md`, `docs/ARCHITECTURE.md`, the build manifests): one agent at a time.
- Commit your files by their paths, never with `git add -A`.
- Delegate broad searches to subagents; keep their conclusions, not the files they read.

## Language

Everything in the repository is in English.
