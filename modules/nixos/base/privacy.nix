{
  # Telemetry opt-outs read by CLI tools (gh, and any tool honouring DO_NOT_TRACK)
  environment.sessionVariables = {
    DO_NOT_TRACK = "1";
    GH_TELEMETRY = "0";
  };
}
