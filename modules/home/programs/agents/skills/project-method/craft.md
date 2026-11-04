# Craft: code and documents

The standard for code and documents in every project. The reader is a developer or an agent who has
never seen the project, at any level, whether they work on it or only use it.

## Code

- **Names say what things are.** Whole words, no private abbreviations; a name that needs a comment
  is the wrong name.
- **A function holds one idea.** A part is split out when it has a name and a job of its own; flat
  control flow, early returns rather than deep nesting.
- **The obvious solution over the clever one.** A trick needs a measurement that proves it worth
  its cost, and a comment that explains it.
- **Types carry the rules.** Make invalid states impossible to build rather than checked
  everywhere; units and ranges in the types or the names.
- **Comments say why**: the reason, the invariant, the unit, the source of a figure. Never what the
  code already says. No commented-out code.
- **Errors say what went wrong and what to do**, with the context needed to act: the file, the
  value, the step.
- **Modules follow responsibilities**, each with a short description of its role at its top.
- **A small public API**, documented, with examples that compile and run.
- **Generics, macros and traits only where they pay** for the reading they cost.
- **Tests read as specifications**: their names say the behaviour they check.
- **One style**: the formatter's, the linter's, the project's conventions in its ADRs.
- **Performance is designed in**: the algorithm and the data's layout are chosen for the budget when
  the code is written; measurement then confirms them.
- **Logs say what happened**, at the right level, without personal data; a crash leaves the context
  needed to find its cause.
- **Tests are deterministic**: they fix their seeds, clocks and order. A flaky test is a bug, never
  retried until it passes.
- **A program can be checked by an agent without a human**: run headless or on a test profile,
  driven by scripted input, its output captured. An interactive program that grows large offers a
  way to drive it, a test harness or an MCP server.
- **Experiments stay out of the main code**: a prototype lives on a branch or a worktree, is
  measured, and is never merged as it is.

## Documents

Each document answers one question for one reader, and has one home, listed in `SKILL.md`: the
README says what the project is and how to run it in five minutes; the reference documentation says
what an item promises; the architecture how the parts fit; the ADRs why.

- **The essential first.** The first sentence of a page or a section says what the reader most
  needs.
- **Plain words, short sentences**, one fact per sentence; lists and tables rather than long
  paragraphs.
- **Examples** wherever an example says more than a sentence; diagrams where they say more than an
  example.
- **Every coined term defined** in the glossary, and linked where it first appears.
- **Each fact once**; other pages link to it.
- **As short as complete**: everything a newcomer needs to understand and change the code, nothing
  more. Length is a cost every reader pays.
- **Updated in the same change as the code** it describes.

## Checking

- **Readability**: a fresh subagent, given one module and its links, explains what it does and,
  through the links, why. What it gets wrong or cannot find is a readability bug.
- **Documentation**: a fresh subagent, given only the repository, follows the README to build, run
  and test the project, and answers a newcomer's questions from the documents alone. Every question
  it cannot answer is a documentation bug.
- Links are checked in CI.
