{
  programs.git = {
    enable = true;
    settings.user = {
      name = "HoneySlatt";
      email = "170786304+HoneySlatt@users.noreply.github.com";
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
