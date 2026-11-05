---
name: project-method
description: The owner's method for every project, large or small, taken from SlimeEngine where it works best. The rules file (AGENTS.md); the project's memory in its repository (PLAN, ROADMAP with its quality bar, ARCHITECTURE, ADRs, glossary, CHANGELOG); small milestones that can be verified, one per session; one check command that CI runs; budgets measured against the top of the field (quality-bars.md); decisions put to the owner one at a time. Use it when the owner starts a project, asks to bring one under the method, plans a stage or sets its budgets, and to review, audit, debug, optimise or write documentation.
---

# The project method

Agents remember nothing from one session to the next. A project keeps its memory and its rules in
its repository, where every session reads them first. SlimeEngine (`~/Projects/SlimeEngine`) is the
reference for the form of ADRs, milestones and `scripts/check.sh`, not for the length of its
documents.

Beside this file, plain files that any agent reads:

- `quality-bars.md`: the references and default budgets of each kind of project;
- `craft.md`: the standard for code and documents, and how to check it;
- `audits.md`: the audits, debugging, edge cases, optimisation and improvements;
- `templates/`: a repository's files to start from.

## What a project holds

Each kind of fact has one home. Other documents link to it, because a fact written twice drifts.

| File | What it holds |
|---|---|
| `AGENTS.md` | The rules for agents: what the project is, what to read, scope, commands, definition of done, rules of the code, when to stop and ask, reporting. Under about 1,500 words. Tracked. `CLAUDE.md` holds only `@AGENTS.md` and stays local. |
| `README.md` | What the project is, its real state, how to build and run it, where to read next |
| `docs/ROADMAP.md` | Direction: stages in order, each with a goal and an exit criterion; the quality bar: references, budgets, how they are measured. The owner decides it. |
| `docs/PLAN.md` | The current stage only, under about 2,000 words: its milestones, their status, how each is checked, the known debt while it fits in a page |
| `docs/debt.md` | The known debt once it outgrows a page: each item short, with why it stays and where it is tracked; the PLAN links to it |
| `docs/audits/` | One file per audit: its scope, findings, decisions and fixes |
| `docs/history.md` | The stages that are done, each in a few lines, with its release and its ADRs |
| `docs/ARCHITECTURE.md` | The parts of the code, their roles, what depends on what, the main flows |
| `docs/adr/NNNN-title.md` | One decision each: context, decision, alternatives rejected, consequences. Only the status changes afterwards. |
| `docs/glossary.md` | The terms the project coins |
| `docs/measurements.md` | What the benchmarks measured, one section per milestone or machine |
| `CHANGELOG.md` | What changed for users, per release |
| `CONTRIBUTING.md` | The environment and the commands in detail |
| `flake.nix` | The development shell: the toolchain and every tool the checks and measurements use |
| `scripts/check.sh` | Every automated check of the definition of done, in one command, benchmarks with budgets included |
| `.github/workflows/ci.yml` | CI, which runs `scripts/check.sh` unchanged on every push |

API contracts live in the code's documentation, not in these files.

## At the size of the project

The method holds for every project; its size follows the project's.

- **Large** (an engine, a game, an application): every file above, stages of several milestones,
  an ADR for each decision.
- **Small** (a TUI, a driver, a library, a tool): the same files, short. A ROADMAP of one or two
  stages with its quality bar; a PLAN; ADRs only for the decisions a newcomer would question;
  `docs/measurements.md`, `docs/history.md` and `CONTRIBUTING.md` only once there is something to
  put in them.

The method is for the owner's own lasting projects. It does not apply to `~/NixOS`, forks, other
people's repositories or one-off scripts.

The bar does not shrink with the size: a small tool is weighed against the best of its kind.

## Bringing a project under the method

Done by the project's own session, which knows its code. Nothing is committed before the owner has
seen the ROADMAP, its quality bar and the list of ADRs.

1. **Inventory.** Read the code and every document. List what the table asks and what exists. Keep
   every good rule that exists: knowledge must not be lost in the move.
2. **`AGENTS.md`**, from `templates/AGENTS.md`, under about 1,500 words. Fill the project's own
   sections; what does not fit goes to its home, with a link.
3. **`docs/ARCHITECTURE.md`**: the code as it is now.
4. **ADRs for the decisions already taken** that a newcomer would question or undo: frameworks,
   platforms, data formats, security, what was tried and abandoned.
5. **`docs/ROADMAP.md`**, proposed: stages with goals and exit criteria, and the quality bar, taken
   from `quality-bars.md` for the project's kind, with the figures adapted. Measure the program as it
   is today, so that the budgets start from facts.
6. **`docs/PLAN.md`**: the current stage, its milestones (goal, delivers, done when, how to test,
   what is measured), a status table, the known debt.
7. **`flake.nix`, `scripts/check.sh` and CI**: a development shell with every tool the checks use;
   build, tests, lints with warnings as errors, formatting, the documentation and its links,
   dependency checks, and the benchmarks that can run there. CI runs the script in that shell.
8. **Show the owner**, in French: the ROADMAP and its quality bar, the ADRs, the rules. Commit after
   the owner's go, one logical change per commit.

## Working under the method

- **At the start of every session**, the tool has loaded `AGENTS.md`. Read the *Current* section of
  `docs/PLAN.md` and the current milestone. Read `docs/ROADMAP.md` and the ADRs when planning, or
  when the task touches a decision; never decide again what an ADR decided.
- **Scope**: the current milestone, or what the owner asks; a request that changes the plan is
  written into `docs/PLAN.md`. A milestone that grows is split, with the owner's agreement. Nothing
  is built because the roadmap mentions it.
- **When a stage ends**, a stage audit (`audits.md`) examines the whole project, and the stage moves
  from `docs/PLAN.md` to `docs/history.md` in a few lines, so that the PLAN stays short. A release
  audit comes before each release.
- **Code and documents** follow `craft.md`: readable by anyone who has never seen them, documents
  as short as complete.
- **Ideas** that are not the current work go to the *Ideas* of `docs/PLAN.md` or to an issue; the
  owner picks which become milestones.
- **Planning a stage**: survey the code and the field first (subagents), then put the stage's
  decisions to the owner one at a time, then record them in an ADR and the milestones in the PLAN.
- **Done** means: the checks pass; the program was run; new behaviour is tested; the budgets the
  milestone touches are measured and met, their figures kept; the PLAN says so; every document
  affected is updated and reread as a newcomer would; every decision a newcomer would question is an
  ADR. Never report as working what was not verified.
- **The owner decides direction**: architecture, product behaviour and look, formats, platforms,
  dependencies, what is costly to undo; one decision at a time, the options with their pros and
  cons in plain terms, a recommendation for the long term. Implementation choices are the agent's,
  stated in the report.
- **Stop and ask** before a decision no ADR covers, a new dependency, a request against the ROADMAP
  or an ADR, a plan that turns out wrong, or deleting or rewriting much of the code.
- **Before reporting a milestone done**, a reviewing agent with fresh eyes, on the strongest model
  available, checks it against `AGENTS.md`, the ADRs and the quality bar.
- **Report**, in the owner's language: what was done; the choices, why, and the alternatives rejected; what to read
  first; the figures measured; shortcuts and debt; then "Prochaine étape … sur ton feu vert".
- **A red CI comes first**: a check that fails on the main branch is fixed before any new work.
- **A session that stops half-way** writes in the milestone, in `docs/PLAN.md`, where it stands,
  what was tried and what comes next, and keeps its unfinished work on a branch.
- **At each stage's end**, the dependencies and `flake.lock` are updated, each in its own commit,
  and CI also runs every week, so that a dormant project still learns of new advisories.
- **Prefer one milestone per session.** The next one starts in a new session, which reads the
  repository again: a long conversation is compressed again and again, loses detail, and carries a
  large context at every turn. If the owner says to continue, continue.
- **Delegate broad searches** to subagents, on a lighter model where the tool allows it; keep their
  conclusions. Do targeted lookups yourself.

## Writing what agents read

`AGENTS.md`, `docs/PLAN.md` and the ADRs' index are read at every session; their size is paid every
time.

- `AGENTS.md` stays under about 1,500 words: rules and links. The commands' detail goes to
  `CONTRIBUTING.md`, what a tool does to its README, what the checks run to the head of
  `scripts/check.sh`.
- Short sentences, one fact per line, lists rather than long paragraphs.
- Nothing that the code or another document already says: link to it.

The owner's standing rules (privileges, git, privacy, how to talk to the owner, the bar) are in the
global rules that every agent reads, kept in `~/NixOS/modules/home/programs/agents/AGENTS.md`; they
are not copied into projects.
