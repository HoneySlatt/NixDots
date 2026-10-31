{ ... }:
{
  programs.opencode = {
    enable = true;
    # Sessions can never be published as public share links
    settings.share = "disabled";
  };
}
