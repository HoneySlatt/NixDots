# One set of rules and skills for every AI agent: agents/AGENTS.md holds the owner's rules and
# agents/skills/ the skills, and each tool reads them where it looks for its own. Change them here,
# then rebuild.
{ lib, pkgs, ... }:
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
  }
  # Claude Code's skills
  // skillsIn ".claude/skills";

  # The skills that Codex, Grok, Kimi and Mistral Vibe share, copied rather than linked: Codex skips a
  # skill whose files are symbolic links.
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.agents/skills"
    for skill in ${skills}/*; do
      target="$HOME/.agents/skills/$(basename "$skill")"
      run rm -rf "$target"
      run cp -rL --no-preserve=mode "$skill" "$target"
    done
  '';

  # OpenCode reads its rules where it looks for its own, which keeps it from falling back on Claude
  # Code's; its skills come through its settings.
  xdg.configFile."opencode/AGENTS.md".source = rules;
  programs.opencode.settings.skills = [ "${skills}" ];

  # What can be checked rather than read: a commit message that credits an AI or names a home folder
  # is refused, by a hook that git runs beside each repository's own.
  programs.git.settings.hook.agent-rules = {
    event = "commit-msg";
    command = "${pkgs.writeShellScript "agent-rules-commit-msg" (builtins.readFile ./agents/commit-msg.sh)}";
  };
}
