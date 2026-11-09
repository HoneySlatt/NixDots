---
name: delegate
description: How a lead agent hands work to another model and checks it, and how a delegated task carries out a brief. The roles and the table of targets for each, in order; a provider that is down; what to delegate and what to keep; the brief as failing tests and acceptance commands, saved with its base commit; hidden checks; proofs kept as files by run.sh; guard.sh, which refuses a diff that touches protected paths or silences a check; one correction round; the ledger; how the table changes. Use it before delegating any search, reading, run, measurement, reproduction, bounded change or review, when checking a delegated result, and whenever you receive a brief that names this skill.
---

# Delegate

The lead decides and integrates; other models read, run, write and review under briefs that a
machine or the lead can check. Rules name roles; the table below is the only place that names
models. Nothing a delegate produces reaches a repository or the owner without a machine check and
the lead's review. The plan and its figures:
`~/NixOS/modules/home/programs/agents/delegation-plan.md`. Below, `<skill>` is this skill's folder:
`~/.claude/skills/delegate/` for Claude Code, `~/.agents/skills/delegate/` for the other tools.

## Roles

- `lead`: talks to the owner, decides, designs, writes briefs, integrates and commits.
- `author-hard`: engine core, `unsafe`, concurrency, GPU, data formats, security.
- `author-bounded`: code under failing tests the lead wrote, in files the brief names.
- `reader`: searches, reads, runs, measures, reproduces, triages CI.
- `web-research`: reads the web, with every source saved.
- `checker`: reads a delegated task's diff with fresh eyes, given the brief, the diff and the
  proofs.
- `reviewer-closing`: the review that closes a milestone, blind to who wrote the code.
- `reviewer-second`: an optional extra review; its findings count only with a failing test.
- `challenger`: attacks a design or a recommendation.

## The table

Each role's targets, in order. *Pluto* is the `target` of `delegate_task`; *Subagent* is the
Claude Code definition (`subagent_type`), which holds the model and the effort; *Mark* names the
provider's file in the down-provider folder (next section).

| Role | # | Model, effort | Pluto | Subagent | Mark |
|---|---|---|---|---|---|
| lead | 1 | Opus 5.5 | `claudeAgent`, `claude-opus-5-5` | the session | `claude` |
| author-hard | 1 | Opus 5.5, xhigh | `claudeAgent`, `claude-opus-5-5`, `{effort: "xhigh"}` | `author-hard` | `claude` |
| checker | 1 | Opus 5.5, high | `claudeAgent`, `claude-opus-5-5`, `{effort: "high"}` | `checker` | `claude` |
| reviewer-closing | 1 | Opus 5.5, max | `claudeAgent`, `claude-opus-5-5`, `{effort: "max"}` | `reviewer-closing` | `claude` |
| challenger | 1 | Opus 5.5, max | as reviewer-closing | `challenger` | `claude` |
| reader | 1 | DeepSeek V4.1 Flash, high; max for hard reading | `deepseekHarness_deepseek`, `deepseek-official/deepseek-flash`, `{reasoningEffort: "high"}` | — | `deepseek` |
| reader | 2, other reading | Sonnet 5.5, high, on trial | `claudeAgent`, `claude-sonnet-5-5`, `{effort: "high"}` | `reader` | `claude` |
| reader | 2, plain searches and runs | Haiku 5.5, high, on trial | `claudeAgent`, `claude-haiku-5-5`, `{effort: "high"}` | `reader-light` | `claude` |
| reader | 3 | none: defer the task | | | |
| web-research | 1 | DeepSeek V4.1 Flash, high, on trial | as reader 1 | — | `deepseek` |
| web-research | 2 | Sonnet 5.5, high, on trial | as reader 2 | `web-research` | `claude` |
| author-bounded | 1 | DeepSeek V4.1 Flash, high, on trial | as reader 1 | — | `deepseek` |
| author-bounded | 2 | Sonnet 5.5, high, on trial | as reader 2 | `author-bounded` | `claude` |
| author-bounded | 3 | Opus 5.5, xhigh | as author-hard | `author-hard` | `claude` |
| reviewer-second | 1 | DeepSeek V4.1 Flash, max | as reader 1, `{reasoningEffort: "max"}` | — | `deepseek` |
| reviewer-second | 2 | none: skip it | | | |

- Take the first row you can reach whose provider is not marked down. Two rows with the same
  number are one step: take the one whose condition fits the task. When no row is left, a role
  whose last row is not "none" waits for its provider's reset.
- A row you cannot reach (no `delegate_task` in your tool) is skipped, never marked down.
- A Claude Code lead reaches a Claude row through its role subagent, never a built-in one (Explore,
  general-purpose, a fork), with no `model` or `effort` in the call: the definition holds them
  (`~/NixOS/modules/home/programs/agents/claude-agents/`). Every other target, and every target of
  another lead, goes through `delegate_task`.
- Fable is never used.
- A web-research brief names the independent sources to read first; for figures on models, the
  boards of Vals AI, Artificial Analysis and Scale. Research on which model to use is never done by
  a model on trial: it falls to the lead.
- A model "on trial" holds its row until evaluation decides (*Changing the table*).

## A provider that is down

- A failure that will not pass by itself is noticed once and never retried: `QUOTA`,
  `ACCOUNT_QUOTA` or `AUTH` from DeepSeek Harness, `usageLimitExceeded` from Codex, Claude's usage
  limit (its message gives the reset time), "cannot run a child task" from Pluto. It does not count
  as a correction round.
- The lead then marks the provider down and takes the next row: `provider-check --down <mark>
  <code> [<check-after>]`, for example `provider-check --down claude USAGE_LIMIT "2026-11-09
  19:00"` (local time, unless the time names a zone). It writes
  `~/.local/state/agents/providers/<mark>` through a temporary file and a rename, under a lock:

  ```
  since: 2026-11-09T14:02Z
  code: QUOTA
  check-after: 2026-11-10T14:02Z
  ```

  `check-after` is the reset time for Claude, 24 hours after `since` otherwise (the default). Where
  `provider-check` is not installed, write the same three lines, in UTC, the same way, and skip
  the marks whose `check-after` has passed.
- Every lead runs `provider-check --list` before choosing a target: it deletes the marks whose
  `check-after` has passed and prints the others. A mark is also deleted when `provider-check
  <mark>` reports the provider available, or when the owner says the account was topped up.
- `provider-check <mark>` checks only `deepseek` for now: DeepSeek's balance, with Pluto's
  DeepSeek Harness key. It prints `is_available`, the balance, and whether it deleted the mark.
  Its exit code:
  - 0: available; the mark is deleted, unless a lead wrote it during the check;
  - 1: unavailable; mark it down if it is not;
  - 3: an error (no key, network, a refused key, an unreadable answer, a folder it cannot
    change); the mark is kept;
  - 4: a mark it cannot check, such as `claude`, which expires at its `check-after`.
- Before a task in its own worktree, check the provider first, with `provider-check` or a tiny
  read-only task: the project's setup runs before the model's first call.

## What to delegate

Delegate when the task reads or runs much more than the lead must check, and the check is a
command or a few cited lines:

- searches in the code and on the web; reading and summarising big documents;
- running checks, tests and benchmarks; triaging CI logs;
- reproducing a bug and shrinking the reproduction;
- code bounded by failing tests that the lead wrote, in files the brief names;
- review packs: the full diff, the ADRs and documents it touches, the results of the checks;
- extra verification: the newcomer documentation test and the readability test (`craft.md`),
  edge cases (`audits.md`), a second review.

Keep for the lead, or for the `author-hard` and reviewer rows:

- every exchange with the owner, every decision, design and architecture;
- the hard code, closing reviews and design challenges;
- a root cause that a delegate has not found in two tries;
- what costs more to brief and check than to do: a rename, a small edit, an ADR or a report
  (editing a draft up to standard costs as much as writing it).

## Launching

1. Write the brief (below) and save it, from the repository the task works in: `bash
   <skill>/brief.sh <task-id> <file>` writes `.delegation/<task-id>/brief.md` with its base commit.
   Each task, and each correction round, gets its own id: letters, digits, `.`, `_`, `-`.
2. Write 1–3 hidden checks that the delegate never sees: a test, a command, or a list of the rules
   a document must keep. Keep them in `~/.local/state/agents/hidden/<repository's folder
   name>/<task-id>/`, never in the brief, the project or `.delegation/`.
3. Launch with the brief's text. A task that edits files runs in its own worktree, which must
   start from the brief's base commit: commit first. Pluto's `isolation: "worktree"` starts from
   the last local commit, in the thread's own project. A Claude Code subagent's `isolation:
   "worktree"` starts there only if Claude Code's setting `worktree.baseRef` is `"head"`; otherwise
   it starts from `origin`'s default branch. Where neither fits (another repository, that setting
   unset), add the worktree yourself (`git worktree add <path> <base>`), install its dependencies,
   and name its path in the brief. Read-only tasks share the checkout.
4. Wait with one blocking call or the completion notice, never by polling.

## The brief

Write it in English, with these headings:

- **Goal**: one sentence.
- **Skill**: "Follow the delegate skill, section *Carrying out a brief*." and the task id.
- **Scope**: the files and directories it may change; everything else is read-only.
- **Forbidden**: commit, push, new dependency, changes outside scope, and anything the project's
  `AGENTS.md` forbids. Name the tests it must not edit.
- **Done when**: the failing tests, with their expected values, that must pass; the documents that
  must change; the helpers to reuse, by path; each acceptance command.
- **Report**: what the final message must hold (see below), and any figure to bring back.

Reading the diff cannot show what is missing. The brief carries what the lead would otherwise have
to catch: the edge cases as tests, the documents to update, the helpers that already exist.

## Carrying out a brief

For the agent that receives a brief:

- You never delegate, schedule work, open threads, message other sessions or ask for secrets. You
  read nothing outside the project, its `.delegation/` folder, this skill and the paths the brief
  names. You reach the web only through `run.sh curl`, so that every page is saved. You never
  commit or push: the lead commits after checking.
- Run every acceptance command, and every command whose result you report, through
  `bash <skill>/run.sh <task-id> -- <command>`. Add `--exclusive` before `--` for measurements
  and benchmarks.
  Its files under `.delegation/<task-id>/` are the proof; a result stated without them is unverified.
- Quote code and documents as `path:line` followed by the exact text.
- A claim that something is absent ("nothing else uses it") comes with the search commands you ran.
- Stay in scope. If the brief is wrong or the task needs more, stop and say so in the report.
- Write the report to `.delegation/<task-id>/report.md`, then give the same text as your one final
  message: what changed, by path; each command run with its exit code and its proof file; the
  figures asked for; doubts, and what was not verified and why.

## Checking a result

1. Read `.delegation/<task-id>/report.md` and the proof files it cites.
2. Run `bash <skill>/guard.sh <base> --protect <each test the brief froze>
   --doc <each document that must change>`, plus `--allow <regex>` for what the brief allowed (for
   example `'\.unwrap\(\)'` in test code). It must pass.
3. Run the acceptance commands and the hidden checks yourself. Check each quote with `grep -F`, and
   run each search for an absence again.
4. For a task that changed files, have the whole diff read with fresh eyes by a `checker`
   subagent, under its own task id (`<task-id>-check`), given the brief, the diff and the proofs,
   rather than in your own large context.
5. If something is wrong, send one correction round: a new task, with its own id and saved brief,
   that holds the brief, the findings and the proofs. If the second result fails too, do the task
   yourself, and note why in the project's `docs/PLAN.md`.

## Ledger

One line per delegated task in `~/.local/state/agents/delegation-ledger.md` (local, never
committed): date, project, task id, role, kind, model and effort, outcome, accepted first time (yes
or no), correction rounds, hidden checks passed (as `2/3`), the child's cost, the lead's cost,
defects found later, a note. Costs are in tokens or dollars where Pluto or the transcripts show
them, `?` otherwise. Outcomes: merged as delivered, fixed by the lead, replaced, failed, provider
down. Kinds: search, reading, run, measurement, reproduction, bounded code, review pack, extra
verification. A defect found later in a delegated change is added to its line.

## Changing the table

- A change of model in a role is proposed to the owner by an agent, with figures and proofs; the
  owner decides. The table and the subagent definitions then change together, and the owner
  rebuilds.
- A model on trial in a role replays saved briefs from their base commits, unattended, and is
  scored on their hidden checks; no doubles, no model judge. A cheaper model is proposed only if it
  is never worse there, and dropped after 2 failures in 3. The proposal says how little a handful of
  tasks can prove.
- The review of models runs only when the owner asks: the independent boards, the plan pages of the
  providers the owner pays or considers, the ledger and the replays, then a proposal with figures,
  sources and dates. Before a subscription renews, the lead may suggest one.
- The owner's accounts and spend stay local, in `~/.local/state/agents/accounts.md`, never in a
  repository.

## Another model leads

- Whichever model leads, it reads the same rules and this skill, and the findings of a
  `reviewer-closing` review bind it: fix them or ask the owner.
- A lead in DeepSeek Harness calls `delegate_task` with `mode: "async"`: it cuts any tool call at
  60 seconds.

## Files

- `brief.sh`: saves a brief with its base commit.
- `run.sh`: runs one command and keeps its proof.
- `guard.sh`: checks a diff against the brief, and against the terms kept out of public
  repositories (`public-check`, global rules section 7).
- `test.sh`: tests all three, in a throwaway repository: `bash test.sh`.
- `provider-check` is installed by Nix, not kept here: `~/NixOS/modules/home/programs/agents/`
  holds it and its tests.
