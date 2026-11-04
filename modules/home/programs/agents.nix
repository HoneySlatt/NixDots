# One set of rules and skills for every AI agent: agents/AGENTS.md holds the owner's rules and
# agents/skills/ the skills, and each tool reads them where it looks for its own. Change them here,
# then rebuild.
{ ... }:
let
  rules = ./agents/AGENTS.md;
  skills = ./agents/skills;
  # Each skill's files linked one by one, so that skills the tools install themselves can sit beside
  # them.
  skillsIn = target: {
    ${target} = {
      source = skills;
      recursive = true;
    };
  };
in
{
  home.file = {
    # Claude Code
    ".claude/CLAUDE.md".source = rules;
    # Codex
    ".codex/AGENTS.md".source = rules;
    # Grok
    ".grok/AGENTS.md".source = rules;
    # Mistral Vibe
    ".vibe/AGENTS.md".source = rules;
    # Kimi Code
    ".agents/AGENTS.md".source = rules;
    # Read by the agents that look above the folder they work in
    "AGENTS.md".source = rules;
  }
  # Claude Code's skills
  // skillsIn ".claude/skills"
  # The skills that Codex, Grok, Kimi and Mistral Vibe share
  // skillsIn ".agents/skills";

  # OpenCode, through its settings
  programs.opencode.settings = {
    instructions = [ "${rules}" ];
    skills = [ "${skills}" ];
  };
}
