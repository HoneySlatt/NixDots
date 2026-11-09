# One set of rules and skills for every AI agent: agents/AGENTS.md holds the owner's rules and
# agents/skills/ the skills, and each tool reads them where it looks for its own. Change them here,
# then rebuild.
{ lib, pkgs, ... }:
let
  rules = ./agents/AGENTS.md;
  skills = ./agents/skills;
  # A script of agents/, with the tools it calls on its PATH; shellcheck checks it at build time.
  script = name: inputs: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = inputs;
    text = builtins.readFile ./agents/${name}.sh;
  };
  publicCheck = script "public-check" (with pkgs; [ coreutils gawk git gnugrep gnused ]);
  # The marks of providers that are down, and whether one is back (the delegate skill, section "A
  # provider that is down").
  providerCheck = script "provider-check" (with pkgs; [ coreutils curl gnused jq util-linux yq-go ]);
  headlessInner = script "agent-headless-inner" (with pkgs; [ coreutils dbus iproute2 sway-unwrapped util-linux weston ]);
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
    # Claude Code's subagents for the Claude rows of the delegate skill's table, each with its model
    # and effort. The folder is linked whole, read-only: home-manager's claude-code module notes that
    # Claude Code's agent scanner takes only regular files, so one link per file could be skipped.
    # A real ~/.claude/agents folder must be moved away before switching.
    ".claude/agents".source = ./agents/claude-agents;
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

  # The terms the owner keeps out of public repositories, from a local list that no repository holds
  # (agents/public-check.sh): refused in the lines a commit adds and in its message.
  programs.git.settings.hook.public-terms = {
    event = "pre-commit";
    command = "${publicCheck}/bin/public-check --staged";
  };
  programs.git.settings.hook.public-terms-message = {
    event = "commit-msg";
    command = "${publicCheck}/bin/public-check --message";
  };

  # The agents' commands: public-check, provider-check, and running a program with a window away
  # from the owner's desktop, data and network, or on the desktop on purpose: the services that run
  # agents have no display (agents/isolation.nix).
  home.packages = [
    publicCheck
    providerCheck
    (script "agent-headless" (with pkgs; [ coreutils systemd util-linux ] ++ [ headlessInner ]))
    (script "owner-desktop" (with pkgs; [ coreutils gnused systemd ]))
  ];
}
