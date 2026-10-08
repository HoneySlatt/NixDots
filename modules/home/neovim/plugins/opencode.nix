let
  # Terminal split on the right, a quarter of the editor wide
  terminal = action: ''
    function()
      require("opencode.terminal").${action}("opencode --port", {
        split = "right",
        width = math.floor(vim.o.columns * 0.25),
      })
    end
  '';
in
{
  programs.nixvim = {
    plugins.snacks.enable = true;

    plugins.opencode = {
      enable = true;
      settings.server = {
        start.__raw = terminal "open";
        toggle.__raw = terminal "toggle";
      };
    };

    opts.autoread = true;
  };
}
