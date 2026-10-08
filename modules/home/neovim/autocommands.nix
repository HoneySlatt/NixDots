{
  programs.nixvim.autoCmd = [
    {
      event = "FileType";
      pattern = "markdown";
      callback.__raw = ''
        function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
        end
      '';
    }
  ];
}
