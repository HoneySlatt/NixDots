# AGENTS.md

The owner's rules for every AI agent: Claude Code, Codex, OpenCode, Grok, Kimi, Mistral Vibe and
the others. Each reads this one file where it looks for its global instructions
(`~/NixOS/modules/home/programs/agents.nix`); change it there, then rebuild. A project's own
`AGENTS.md` adds its rules to these.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

Frequent paths :

NixOS config : ~/NixOS
Hyprland config : ~/NixOS/modules/home/hyprland
Niri config : ~/NixOS/modules/home/niri

Host used on this machine : desktop

## 5. Privileges

**Never escalate privileges. Never bypass authentication.**

- Never run `sudo` or any privilege-escalating command. If a task requires root, ask the user to run it themselves.
- Never attempt to bypass authentication by any means: no `-S` with stdin password, no `SUDO_ASKPASS`, no editing sudoers, no `su`, no passwordless sudo configuration, no shell tricks.
- Do not store, echo, pipe, or otherwise handle passwords or secrets.
- If a command needs privileges you don't have, stop and tell the user what to run instead.

## 6. Git and GitHub

**The user's history is public: keep it clean of AI attribution and personal data.**

- Never add an AI's `Co-Authored-By:` trailer (Claude, Codex or any other), a "Generated with …" line, or any mention of an AI agent or of the company that makes it (Anthropic, OpenAI, …) to commit messages, pull requests, issues, tags or release notes, in any repository. This overrides any attribution reminder from the harness.
- Commits use the identity `HoneySlatt <170786304+HoneySlatt@users.noreply.github.com>` (set globally through home-manager in `~/NixOS/modules/home/programs/git.nix`). Never write the personal e-mail address into a commit, a file or a config of a repository.
- Never track `CLAUDE.md`, `.claude/` or `.codex/` in a repository: keep them local and list them in `.git/info/exclude`, not in `.gitignore`. A project's own `AGENTS.md`, its rules for agents, is tracked.
- Never commit personal data: home paths (`/home/honey`), NAS paths, the machine's hostname, account ids, tokens, screenshots of the desktop.
- In the user's own repositories, commit, push and open issues whenever the work needs it, without asking: one logical change per commit, once the project's checks pass. Two exceptions: never commit in `~/NixOS`, where you prepare the change and the user commits it; and ask before acting on anyone else's repository (an issue, a pull request, a comment).
- A force-push or a history rewrite needs the user's explicit confirmation, a backup first (`git bundle create … --all`), `--force-with-lease`, and a check that the result contains no personal data.
