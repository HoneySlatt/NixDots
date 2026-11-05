# Design: before building

How the owner and the agents decide what to build before anything is built: a new project, a
stage, a large feature, a rewrite, a change of framework, format or architecture, or a question of
the owner's like "what is possible for this". A small feature inside a milestone needs none of it.

A design session builds nothing. What it produces is decisions and a plan, written down. Code is
written only for a prototype that answers a question (step 5).

## Steps

1. **The need.** What the owner wants, in the owner's words; for whom; what must stay true (the
   bar, the range of hardware, the platforms, the user's data). Ask about what is unclear before
   searching. Time is not a constraint unless the owner says so.
2. **The ground.** What the project already has, its ADRs and its debt. What the field does: the
   best programs of the kind, the libraries, the papers, the platforms' current documentation.
   Broad surveys go to subagents in parallel; sources are kept, facts checked against current
   documentation.
3. **Options.** At least two real ones, honestly argued, including keeping what exists or not doing
   it when that is a real choice. For each: what it gives, what it costs to build and to maintain,
   its risks, what it rules out later, how it meets the quality bar on the high tier and on the
   lowest machine supported. Figures where they exist, each marked measured or estimated.
4. **Challenge.** A fresh subagent, on the strongest model available, attacks the recommendation:
   what the best team in the field would do differently, what breaks at ten times the size, on the
   lowest machine, in five years. The recommendation survives, or changes.
5. **Prototype**, only when a choice turns on a figure nobody knows: the smallest program that
   answers it, on a branch or in a worktree, measured, then thrown away; its figures are kept.
6. **Put to the owner**, in French, one decision at a time: the options, their pros and cons in
   plain terms, a recommendation for the long term. An idea better than what was asked is proposed
   too. A counter-proposal of the owner's is weighed as honestly as the agent's own: if it is worse
   for the bar, say why, once, with facts; then follow the owner's choice.
7. **Record.** Each decision in an ADR, with the options rejected and why. The stages and the
   quality bar in `docs/ROADMAP.md`; the questions still open in its open decisions; the milestones
   in `docs/PLAN.md`. A design session that stops half-way writes in the PLAN where it stands.

## A new project

The design comes before the first line of code. The repository starts with the method's files
(`SKILL.md`): its first commits hold the ROADMAP with its quality bar, the first ADRs and the PLAN
of the first stage, after the owner's go.

## A rewrite

Besides the steps above, it states:

- what is kept: behaviour, the user's data and its formats, the tests that prove parity;
- how the user's data moves to the new version, and how it is checked;
- whether it can be done step by step, the program working at each step, rather than all at once;
- how parity is judged, and when the old code is removed.
