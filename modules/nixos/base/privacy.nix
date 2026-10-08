{
  # Telemetry opt-outs read by CLI tools (gh, and any tool honouring DO_NOT_TRACK)
  environment.sessionVariables = {
    DO_NOT_TRACK = "1";
    GH_TELEMETRY = "0";
  };

  # Applies to every Claude Code launch, terminal or Claude Desktop: no telemetry,
  # error reporting, bug reports or update checks
  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
    env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };
}
