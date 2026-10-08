{
  imports = [
    ./settings.nix
    ./languages.nix
    ./agents.nix
    ./themes.nix
    ./debug.nix
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "lua"
      "docker-compose"
      "dockerfile"
      "env"
      "git-firefly"
      "make"
      "github-actions"
    ];
  };
}
