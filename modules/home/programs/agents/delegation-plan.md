# Plan: delegation between AI models

The owner's agents hand work from one model to another through Pluto's `delegate_task`, or a
tool's own subagents, whichever provider leads and whichever receives. Rules and skills name roles;
one table maps each role to models, and changes as models come and go. This file holds the plan
while it is carried out; once done, its rules move into `AGENTS.md` and the `delegate` skill, and
this file is deleted.

The owner's accounts and spend are personal and stay local: `~/.local/state/agents/accounts.md`.

## Goal

The least Claude quota per milestone at equal quality, counting what the lead spends to brief and
check. Context is the larger lever: since 2026-11-06, 76 % of Claude spend is context read again
(cache reads and writes), and routing alone moves about 10 %. The document diet (step 5) works on
context; this plan works on routing.

## Facts (2026-11-09)

- **Independent figures**, Terminal-Bench 4.0 (Vals AI, 2026-11-05): Opus 5.5 65.2 %, Sonnet 5.5
  64.1 %, Kimi K3.1 Pro 63.6 %, GPT-6 Astra 59.6 %, GPT-6.1 Sol 55.1 %, Haiku 5.5 36.4 %, DeepSeek
  V4.1 Flash 31.8 % (its vendor says 42.3 %). Cost per task there: Opus $12.04, Kimi $4.57, GPT-6.1
  Sol $1.72, DeepSeek Flash $0.54. No serious independent benchmark exists for code review or web
  research. Vendor figures run up to 9 points above the boards.
- **Prices** per million tokens (input / cached / output): Opus 5.5 4 / 0.20 / 20; Sonnet 5.5
  2 / 0.10 / 10; Haiku 5.5 0.10 / 0.01 / 0.50 up to 100k-token prompts, 0.50 / 0.05 / 2.50 above;
  DeepSeek V4.1 Flash 0.30 / 0.006 / 1.20, half off-peak. Sources and saved pages:
  `~/NixOS/.delegation/multimodel-landscape-1/` (local).
- **Pluto** (`~/Projects/pluto-server`, `981056cf08`), read twice:
  - Every provider can be a child of `delegate_task`, except Ollama in code projects. Model,
    reasoning option, runtime mode (never broader than the parent's) and worktree isolation reach
    the child. Its summary is its last message.
  - Every provider can lead and call Claude (Kimi only through `~/.kimi-code/mcp.json`), but
    DeepSeek Harness, Kimi Code and Mistral Vibe get the tool without Pluto's how-to text.
  - DeepSeek Harness cuts any tool call at 60 s: from it, only `mode: "async"` works.
  - A delegated task can delegate again, with no depth or concurrency limit, and holds all 17
    tools (`schedule_task`, `create_threads`, `request_secret`).
  - A child's usage is not added to its parent's; no cost per delegated task exists yet.
  - Out of credit, DeepSeek Harness reports `QUOTA` (HTTP 402), without retry. Pluto's summary:
    "DeepSeek Harness reported a model error (QUOTA)". DeepSeek's `GET /user/balance` answers
    `is_available`. Pluto knows Claude's 5-hour and weekly windows but does not expose them.
- **Practice of the field** (`~/NixOS/.delegation/routing-practice-1/report.md`, 58 sources):
  fix roles, not models; decide on one's own tasks, paired; 30 tasks resolve only differences of
  15–20 points; a model judge favours its own family; switch models only between tasks.
- **Ledger**, 15 tasks: measurement, reading and searches mostly sound. Bounded code passed every
  test twice, but Opus found a real defect both times, through tests it added afterwards. 4 of 7
  document diets dropped rules. One survey of models missed the independent boards.

## Owner's decisions

2026-11-08:

1. Everything may be sent to DeepSeek, in every project. Secrets never are (global rules).
2. One milestone per session; no token threshold.
3. Size limits enforced by each project's `check.sh` (`AGENTS.md`, `docs/PLAN.md`); the PLAN's
   *Current* section holds status only. One clean-up pass per project, by DeepSeek, reviewed by
   Opus. Splitting big documents waits for measurements.
4. Replaced by decision 9.

2026-11-09:

5. Every provider may receive everything except secrets.
6. The lead is whichever model is best at the job, not necessarily Claude. A change of model in a
   role is proposed by an agent with figures and proofs; the owner validates.
7. Goal and form: as in *Goal* and *Design*. One table, role to models in order, in the
   `delegate` skill, active through the owner's rebuild. Counters and money stay local. No timer.
8. Haiku 5.5 and Sonnet 5.5 may hold reading roles and fallbacks, on trial. Opus keeps the lead,
   the hard code, the closing review and design challenges. Fable is never used.
9. Evaluation by saved briefs, hidden tests and replays, without Opus doubles or a model judge.
   The rule "the first three tasks of each kind done twice" ends.
10. The Max plan's included API credits: later.
11. Personal figures (accounts, spend, balances, renewals, the ledger) stay out of `~/NixOS`, which
    is public.
12. The review of models runs only when the owner asks for it.
13. A provider out of credit or quota is never called in a loop: the lead notices it once and
    falls back on its own, ending with Claude's models.
14. Sonnet 5.5 is on trial in web-research too, so research on which model to use falls to the
    lead (asked while building step A).
15. Effort max stays for the closing review and challenges. Each delegated task that changed files
    is checked by a new `checker` role, Opus at effort high (asked while building step A).

## Design

### Roles

`lead` talks to the owner, decides, designs, writes briefs and integrates. `author-hard` writes
engine core, `unsafe`, concurrency, GPU, data formats and security. `author-bounded` writes code
under tests the lead wrote. `reader` searches, reads, runs, measures, reproduces and triages CI.
`web-research` reads the web with sources. `checker` reads a delegated task's diff with fresh
eyes. `reviewer-closing` reviews a milestone, blind to authorship. `reviewer-second` adds an
optional review whose findings count only with a failing test. `challenger` attacks a design.

### The table (in the `delegate` skill)

| Role | Targets, in order |
|---|---|
| lead, author-hard, checker, reviewer-closing, challenger | Opus 5.5, effort max for reviews and challenges, high for `checker`. When Claude's window is out: wait for its reset. |
| reader | DeepSeek V4.1 Flash, high (max for hard reading); then Sonnet 5.5 (Haiku 5.5 for plain searches and runs), on trial; then defer. |
| web-research | DeepSeek V4.1 Flash, on trial, the brief naming the independent boards; then Sonnet 5.5, on trial. Research on which model to use is never done by a model under evaluation. |
| author-bounded | DeepSeek V4.1 Flash, on trial; then Sonnet 5.5, on trial; then Opus 5.5. |
| reviewer-second | DeepSeek V4.1 Flash, max; else skipped. |

Each row gives the Pluto target (provider instance, model, options). Claude's targets also exist as
Claude Code subagent definitions, so that Claude Code applies their model and effort. Adding a
provider means adding rows; nothing else changes.

### A provider that is down

- A non-transient failure is noticed once: `QUOTA`, `ACCOUNT_QUOTA` or `AUTH` from DeepSeek
  Harness, `usageLimitExceeded` from Codex, "cannot run a child task" from Pluto. It is never
  retried and does not count as a correction round.
- The lead writes `~/.local/state/agents/providers/<provider>` with `provider-check --down`: since
  when, the code, when to check again (a temporary file, then a rename). Every lead runs
  `provider-check --list` before choosing a target, then takes the next row of the table.
- The mark is cleared at the window's reset time for Claude, or by `provider-check deepseek` (the
  key sent in a header; it prints only `is_available` and the balance; agents never open a
  credential file), or by the owner after a top-up, or after 24 hours.
- Before a worktree task, the lead checks the provider first: a project's setup runs before the
  model's first call. A read-only task that fails costs seconds.

### Delegation contract

The brief, `run.sh` proofs, `guard.sh`, one correction round and the ledger stay as they are, plus:

- The brief and its base commit are saved as `.delegation/<id>/brief.md`.
- The lead keeps 1–3 hidden tests or checks the delegate never sees (rule retention for a document
  diet, for example), and runs them on the result.
- A delegated task never delegates, schedules, opens threads or messages other sessions; it reads
  nothing outside the project, `.delegation/`, the `delegate` skill and the paths its brief names.
  Web research reaches the web only through `run.sh curl`.
- The lead checks a result in a fresh subagent rather than in its own large context.
- The ledger records per task: role, model and effort, the child's cost, the lead's cost, the
  outcome (merged as delivered, fixed by the lead, replaced, failed, provider down), hidden tests
  passed, defects found later.

### Evaluation

A model on trial in a role replays saved briefs, unattended, and is scored on their hidden tests.
A cheaper model is proposed only if it is never worse there; it is dropped after 2 failures in 3.
The proposal states how little a handful of tasks can prove.

### Another model leads

The shared rules and the neutral skill reach every tool. When a non-Claude lead calls Claude for
the hard code or the closing review, the review's findings bind it: fix them or ask the owner.
Pluto's fixes for non-Claude leads (the how-to text for DeepSeek Harness, Kimi Code and Mistral
Vibe; DeepSeek Harness's 60 s cut) wait until such a lead is chosen on evidence.

### Review of models, at the owner's request

Read the independent boards (Vals AI, Artificial Analysis, Scale) and the plan pages of the
providers the owner pays or considers; compare with the ledger and replays; write a proposal with
figures, sources and dates; the owner decides. Before a subscription renews, the lead may suggest
one.

## Steps

1. Done: the baseline (`~/.cache/agent-baseline/`).
2. Done and rebuilt: Pluto `17ce1c3c0e`, `d9dda4b940`, `981056cf08`: a delegated task's summary is
   its last message; DeepSeek Harness reports token usage; provider errors log their real cause.
3. Done and rebuilt: the `delegate` skill, with `run.sh`, `guard.sh` and the ledger.
4. Done and rebuilt: the safety rules moved from Claude's memory into `AGENTS.md` sections 6 and 7
   (`public-check`, `isolation.nix`, `agent-headless`, `owner-desktop`). Still open: delete the
   memory notes those rules now repeat; the logo's series in the terms list (the owner); a home for
   the desktop shell's test rules.
5. The document diet, project by project: the first pilot tasks, done twice per decision 4.
   Running in SlimeEngine, Opium and Slatty; it finishes under the old rule.
6. **A. Skill and rules.** Built 2026-11-09, waiting for the owner's commit, and for the rebuild
   once step 5 ends (the step-5 sessions run under the old skill until then):
   - the `delegate` skill names models only in its table, with each row's Pluto target and Claude
     Code subagent; `brief.sh` saves a brief with its base commit (tested in `test.sh`); hidden
     checks live in `~/.local/state/agents/hidden/`, kept from delegates by the read scope only;
   - eight subagent definitions in `agents/claude-agents/`, linked whole as `~/.claude/agents` by
     `agents.nix`; each withholds `Agent`, messaging, scheduling, `WebFetch`, `WebSearch` and
     Pluto's tools;
   - `AGENTS.md` section 5 points to the skill; this file renamed; the ledger has the new columns;
     the memory notes are updated.
   Checked before the rebuild, with the built folder linked as a project's `.claude/agents`. Claude
   Code listed the first seven; `checker` came later, built the same way. From a Haiku parent at
   effort low, it ran `reader` on Sonnet 5.5 at effort high, and `reader-light` without the
   withheld tools.
   Claude Code starts a subagent's worktree from `origin`'s default branch unless its setting
   `worktree.baseRef` is `"head"` (read in Claude Code 2.1.318's settings schema). The owner sets
   it; until then the skill gives editing Claude tasks a worktree made by hand, and `guard.sh`
   refuses a base that is not an ancestor of the result.
   Any rebuild turns step A on, since its files are tracked. Until then, the installed old skill
   points to this file's old name, and step-5 sessions write ledger lines in the old 7 columns:
   convert them at the rebuild. Still open: the project method's `SKILL.md`, `audits.md`,
   `design.md` and its `AGENTS.md` template still say "strongest model" and "lighter model": point
   them to the roles. Step D measures whether web research without `WebSearch` (pages only through
   `run.sh curl`) is good enough.
7. **B. Provider state.** Built 2026-11-09, waiting for the owner's commit and rebuild:
   - `agents/provider-check.sh`, installed by `agents.nix`: `provider-check deepseek` asks
     DeepSeek's `GET /user/balance`, prints `is_available` and the balance, and deletes the mark
     when available; `--down` writes a mark atomically under a lock; `--list` deletes expired marks
     and prints the others. Exit codes: 0 available, 1 unavailable, 2 usage, 3 error, 4 no check
     for that mark.
   - The key: Pluto gives each DeepSeek Harness instance its own home and strips `DEEPSEEK_*` from
     its environment, so the Harness reads `refs.DEEPSEEK_API_KEY` from
     `~/.pluto/userdata/deepseek-harness/deepseekHarness_deepseek/.credentials.yaml` (mode 600,
     the owner's). The script reads it with `yq` and gives it to curl on standard input.
   - Tests in `agents/test.sh`, against a fake server on 127.0.0.1, with a throwaway `HOME`; one
     real check passed. The closing review's findings (a curlrc reaching curl, an empty answer read
     as unavailable, a check deleting a mark written meanwhile, and five more) are fixed, each
     with a test.
   - The `delegate` skill's section *A provider that is down* now names these commands.
   Still open: `claude` cannot be checked until Pluto exposes the usage windows (step C); a mark
   for it expires at its `check-after`. If DeepSeek Harness's `apiKeyEnv` is ever changed from
   `DEEPSEEK_API_KEY`, the script must follow.
8. **C. Pluto** (its own project, in this order): a delegated task gets no orchestration tools;
   `orchestrator_capabilities` exposes the providers' usage windows; a child's usage is added to its
   parent's.
9. **D. Trials:** Haiku 5.5 and Sonnet 5.5 as reader and fallback; DeepSeek Flash in web research
   and bounded code; by replays of saved briefs with hidden tests.
10. **Later, on the owner's go:** the Max plan's API credits (link a Console organization, then a
    test of a few cents that they pay for a Pluto Claude instance); Pluto choosing the target from
    the role; a pre-commit check of the author's identity.

## Debt

- Every child runs as the owner: any provider's child can read another provider's credential files,
  and the lead's hidden checks. A sandbox per provider is not built; the read scope in briefs is the
  only guard.
- With DeepSeek the only provider besides Claude, no second review from another family exists.
