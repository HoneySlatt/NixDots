# Language server settings shared by Neovim, Helix and Zed
{
  rust-analyzer = {
    check = {
      command = "clippy";
      extraArgs = [ "--" "-W" "clippy::pedantic" ];
    };
    cargo = {
      allFeatures = true;
      loadOutDirsFromCheck = true;
    };
    inlayHints = {
      bindingModeHints.enable = false;
      chainingHints.enable = true;
      closingBraceHints.enable = true;
      closureReturnTypeHints.enable = "always";
      parameterHints.enable = true;
      typeHints.enable = true;
      typeHints.hideClosureInitialization = false;
    };
    procMacro.enable = true;
  };

  gopls = {
    hints = {
      assignVariableTypes = true;
      compositeLiteralFields = true;
      functionTypeParameters = true;
      parameterNames = true;
      rangeVariableTypes = true;
    };
    analyses = {
      unusedparams = true;
      shadow = true;
    };
    staticcheck = true;
  };
}
