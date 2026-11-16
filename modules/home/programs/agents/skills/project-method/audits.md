# Audits

How a project is examined to keep it at the bar: what kinds of audit exist, when each runs, how it
is done, and how debugging, edge cases, optimisation and improvements are handled.

## When

| Audit | When | Depth |
|---|---|---|
| Review | Closes each milestone | The milestone's changes, against `AGENTS.md`, the ADRs and the quality bar |
| Stage audit | Closes each stage | The whole project, every dimension below |
| Release audit | Before each release | The stage audit, plus the release's checklist: changelog, version, signed and reproducible packages, debug symbols kept, the update from the previous release tested, a run on each platform. A patch release needs only the review and the checklist |
| On demand | When the owner asks, or when a measure or a bug suggests drift | The dimensions asked for |

## Dimensions

Each audit names the dimensions it covers. A stage audit covers them all.

- **Correctness**: bugs, wrong results, crashes, panics, unhandled errors.
- **Architecture and evolvability**: dependency directions, boundaries, data ownership and contracts
  match the code and ADRs. Trace representative change scenarios from the quality bar: where would
  a change spread, and can the important parts be tested independently? Support findings with
  concrete code paths and checks, not module counts or claims of modularity.
- **Stability and recovery**: check the quality bar's applicable scenarios for sustained use,
  cancellation, saturation, partial failure, restart and upgrade. Verify bounded resource use,
  valid state after failure and tested recovery; a successful build is not stability evidence.
- **Edge cases**: the checklist below, for what the project handles.
- **Performance**: every budget of the quality bar measured again; profiles of the hot paths.
- **Resources at rest**: CPU, wake-ups, memory, power while nothing happens.
- **Security and privacy**: untrusted input, secrets, permissions, what leaves the machine.
- **Data safety**: formats versioned, migrations tested, writes atomic, nothing lost on a crash.
- **Tests**: each fails when the behaviour it names breaks (mutation testing, `cargo mutants`);
  none skipped, none flaky.
- **Readability**: the code read by someone who has never seen it (`craft.md`).
- **Documentation**: accurate, complete, short, understood by a newcomer (`craft.md`). A topic
  whose rule is spread across ADRs that amend one another is consolidated: one ADR supersedes them,
  the rule stated whole.
- **Dependencies**: updates, advisories, licenses, ones that can go.
- **Accessibility**, for anything with an interface.
- **Debt**: the whole list, triaged as [Debt](#debt) says.

## How

1. **Scope.** Write down the audit's dimensions, the code it covers and the commit it starts from.
2. **Independent reviewers.** One subagent per dimension that applies, each with fresh eyes, given
   the code and the bar, never the expected conclusions; a small project groups the dimensions.
   Judgment calls use the strongest model available.
3. **Verify every finding** before it counts: a test that fails, a measurement, or the exact line
   with the reasoning. Unverified findings are dropped or marked as doubts.
4. **Rank** by severity: data loss, crash or security first; then wrong behaviour; then a missed
   budget; then readability and documentation.
5. **Report to the owner**, in plain terms: what was found, what it costs to fix, a recommendation.
   Fixes that change direction are decided one at a time; the others are planned.
6. **Record** the audit in `docs/audits/YYYY-MM-DD-<scope>.md`: scope, findings, decisions, and
   what was fixed. Open items go to the known debt, each with the milestone that follows it.

## Debt

Debt is noted when it is made: each shortcut that cannot be avoided, with its reason and the
milestone that follows it. It is paid at four moments, never on the side of another task.

1. **At once, what breaks the bar**: a budget missed, a wrong or unsafe behaviour, data at risk.
   The current milestone or the next pays it; it stays debt only by the owner's decision.
2. **When a milestone touches its code**: the milestone that follows an item pays it, or says in
   its report why it puts it off and which milestone follows it now. The code is open and its
   tests run: it costs least then.
3. **At each stage's audit, the whole list triaged**: what is small, paid; what no longer holds,
   deleted; each item left given the milestone that follows it; an item that has had no plan for
   two stages put to the owner, with options.
4. **Before a release**, a milestone of its own pays the debt that the audit found too large to
   leave, rather than letting it ride into the release.

No milestone of debt is cut from the current work, and no item stays without a milestone that
follows it.

## Debugging

1. Reproduce the bug, then make the reproduction as small as possible.
2. Write the test that fails because of it.
3. Find the root cause: ask why until the answer is the code's real mistake, not its symptom.
4. Fix the cause; the test passes; nothing else breaks.
5. Search for the same mistake elsewhere, and fix it there too, in its own commit.
6. If the cause was not obvious, say why in a comment or in the commit's body.

## Edge cases

Go through the list for what the project handles; each case either works, or is refused with a
clear error, and is tested.

- **Input**: empty, a single item, the largest allowed, ten times the expected size, malformed,
  truncated, every writing system, right-to-left text, emoji, paths with spaces or unusual
  characters.
- **Time**: clock changes, time zones, daylight saving, very long uptimes, sleep and resume.
- **Concurrency**: races, re-entrance, cancellation half-way, two instances at once.
- **Failure**: an I/O error, a full disk, a missing permission, the network lost or slow, a device
  lost (GPU, audio), the process killed in the middle of a write, a power loss.
- **Environment**: fractional scales, several monitors, resizes, another locale, no GPU, little
  memory, a slow disk.
- **Security**: untrusted input, injection, path traversal, oversized allocations requested by
  input.

## Optimisation

1. Start from a budget of the quality bar that is missed, or a cost that the owner wants lower.
2. Measure it, with a benchmark kept in the repository.
3. Profile, and find where the time or the memory goes.
4. Change one thing, preferring the algorithm and the data's layout over small tricks.
5. Measure again; keep the change only if the figure moved beyond its run-to-run spread, and record
   it in `docs/measurements.md`.
6. Stop when the budget is met. CI keeps it from coming back.

## Improvements

An idea that is not the current work is written down, in the *Ideas* of `docs/PLAN.md` or as an
issue: what it is, why, and what it would gain. The owner decides which become milestones. Nothing
is improved on the side of another task.
