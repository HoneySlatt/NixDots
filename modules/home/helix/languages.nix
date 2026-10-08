{ pkgs, ... }:

let
  lspSettings = import ../lsp-settings.nix;
  prettierCmd = "${pkgs.prettier}/bin/prettier";
  helixWakatimeLs = pkgs.zed-wakatime-ls.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace wakatime-ls/src/main.rs \
        --replace-fail 'platform.push_str("Zed");' 'platform.push_str("Helix");' \
        --replace-fail '"Zed-wakatime/{}"' '"Helix-wakatime/{}"'
    '';
  });
in
{
  programs.helix.languages = {
    language = [
      {
        name = "rust";
        auto-format = true;
        language-servers = [ "rust-analyzer" "wakatime" ];
        formatter = { command = "${pkgs.rustfmt}/bin/rustfmt"; args = [ "--edition" "2021" ]; };
        indent = { tab-width = 4; unit = "    "; };
        persistent-diagnostic-sources = [ "rustc" "clippy" ];
        debugger = {
          name = "lldb-dap";
          transport = "stdio";
          command = "${pkgs.lldb}/bin/lldb-dap";
          templates = [
            {
              name = "launch binary";
              request = "launch";
              completion = [ { name = "binary"; completion = "filename"; } ];
              args = { program = "{0}"; };
            }
          ];
        };
      }
      {
        name = "go";
        auto-format = true;
        language-servers = [ "gopls" "wakatime" ];
        formatter = { command = "${pkgs.gotools}/bin/goimports"; };
        indent = { tab-width = 4; unit = "\t"; };
        debugger = {
          name = "dlv";
          transport = "tcp";
          command = "${pkgs.delve}/bin/dlv";
          args = [ "dap" ];
          port-arg = "-l 127.0.0.1:{}";
          templates = [
            {
              name = "launch file";
              request = "launch";
              completion = [ { name = "entrypoint"; completion = "filename"; default = "."; } ];
              args = { mode = "debug"; program = "{0}"; };
            }
            {
              name = "launch package";
              request = "launch";
              completion = [ { name = "package"; completion = "directory"; default = "."; } ];
              args = { mode = "debug"; program = "{0}"; };
            }
            {
              name = "attach";
              request = "attach";
              completion = [ "pid" ];
              args = { mode = "local"; processId = "{0}"; };
            }
          ];
        };
      }
      {
        name = "gomod";
        language-servers = [ "gopls" "wakatime" ];
        auto-format = true;
        indent = { tab-width = 4; unit = "\t"; };
      }
      {
        name = "gowork";
        language-servers = [ "gopls" "wakatime" ];
        auto-format = true;
        indent = { tab-width = 4; unit = "\t"; };
      }
      {
        name = "gotmpl";
        language-servers = [ "gopls" "wakatime" ];
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "c";
        auto-format = true;
        language-servers = [ "clangd" "wakatime" ];
        formatter = { command = "${pkgs.clang-tools}/bin/clang-format"; };
        indent = { tab-width = 4; unit = "    "; };
        debugger = {
          name = "lldb-dap";
          transport = "stdio";
          command = "${pkgs.lldb}/bin/lldb-dap";
          templates = [
            {
              name = "launch binary";
              request = "launch";
              completion = [ { name = "binary"; completion = "filename"; } ];
              args = { program = "{0}"; };
            }
          ];
        };
      }
      {
        name = "cpp";
        auto-format = true;
        language-servers = [ "clangd" "wakatime" ];
        formatter = { command = "${pkgs.clang-tools}/bin/clang-format"; };
        indent = { tab-width = 4; unit = "    "; };
        debugger = {
          name = "lldb-dap";
          transport = "stdio";
          command = "${pkgs.lldb}/bin/lldb-dap";
          templates = [
            {
              name = "launch binary";
              request = "launch";
              completion = [ { name = "binary"; completion = "filename"; } ];
              args = { program = "{0}"; };
            }
          ];
        };
      }
      {
        name = "lua";
        auto-format = true;
        language-servers = [ "lua-language-server" "wakatime" ];
        formatter = { command = "${pkgs.stylua}/bin/stylua"; args = [ "-" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "python";
        auto-format = true;
        language-servers = [ "pyright" "ruff" "wakatime" ];
        formatter = { command = "${pkgs.ruff}/bin/ruff"; args = [ "format" "-" ]; };
        indent = { tab-width = 4; unit = "    "; };
        debugger = {
          name = "debugpy";
          transport = "stdio";
          command = "${pkgs.python3Packages.debugpy}/bin/python";
          args = [ "-m" "debugpy.adapter" ];
          templates = [
            {
              name = "launch file";
              request = "launch";
              completion = [ { name = "main"; completion = "filename"; } ];
              args = { program = "{0}"; };
            }
          ];
        };
      }
      {
        name = "javascript";
        auto-format = true;
        language-servers = [ "typescript-language-server" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "jsx";
        auto-format = true;
        language-servers = [ "typescript-language-server" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "typescript";
        auto-format = true;
        language-servers = [ "typescript-language-server" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "tsx";
        auto-format = true;
        language-servers = [ "typescript-language-server" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "html";
        auto-format = true;
        language-servers = [ "vscode-html-language-server" "emmet-ls" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "css";
        auto-format = true;
        language-servers = [ "vscode-css-language-server" "emmet-ls" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "scss";
        auto-format = true;
        language-servers = [ "vscode-css-language-server" "emmet-ls" "wakatime" ];
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
      {
        name = "json";
        auto-format = true;
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" ]; };
        indent = { tab-width = 2; unit = "  "; };
        language-servers = [ "vscode-json-language-server" "wakatime" ];
      }
      {
        name = "markdown";
        language-servers = [ "wakatime" ];
        auto-format = true;
        formatter = { command = "${prettierCmd}"; args = [ "--stdin-filepath" "%{buffer_name}" "--parser" "markdown" ]; };
        indent = { tab-width = 2; unit = "  "; };
        soft-wrap = { enable = true; };
      }
      {
        name = "toml";
        language-servers = [ "wakatime" ];
        auto-format = true;
        formatter = { command = "${pkgs.taplo}/bin/taplo"; args = [ "fmt" "-" ]; };
        indent = { tab-width = 2; unit = "  "; };
      }
    ];

    "language-server" = {
      wakatime = {
        command = "${helixWakatimeLs}/bin/wakatime-ls";
        args = [ "--wakatime-cli" "${pkgs.wakatime-cli}/bin/wakatime-cli" ];
      };

      clangd = {
        command = "clangd";
        args = [ "--background-index" "--clang-tidy" ];
      };

      gopls = {
        command = "gopls";
        config = lspSettings.gopls;
      };

      "rust-analyzer" = {
        command = "rust-analyzer";
        config = lspSettings.rust-analyzer;
      };

      "lua-language-server" = {
        command = "lua-language-server";
        config.Lua = {
          runtime.version = "LuaJIT";
          workspace.checkThirdParty = false;
          telemetry.enable = false;
        };
      };

      pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
      };

      ruff = {
        command = "ruff";
        args = [ "server" ];
      };

      emmet-ls = {
        command = "emmet-language-server";
        args = [ "--stdio" ];
      };
    };
  };

  programs.helix.extraPackages = with pkgs; [
    stylua
    gotools
    gopls
    rustfmt
    rust-analyzer
    clang-tools
    ruff
    pyright
    taplo
    lldb
    delve
    python3Packages.debugpy
    lua-language-server
    prettier
    typescript-language-server
    vscode-langservers-extracted
    emmet-language-server
  ];
}
