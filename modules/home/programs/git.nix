{
  programs.git = {
    enable = true;
    settings.user = {
      name = "HoneySlatt";
      email = "HoneySlatt@tuta.com";
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };
}
