{ lib, pkgs, ... }:

let
  packageUpdater = pkgs.writeShellApplication {
    name = "personal-package-update";
    runtimeInputs = with pkgs; [ curl nix nix-prefetch-git python3 ];
    text = ''
      exec python3 "$HOME/NixOS/pkgs/update.py" "$@"
    '';
  };
  updateCommands = {
    nuvio = "nuvio";
    rqbit-desktop = "rqbit-desktop";
    kimi = "kimi-code";
    kimi-code-desktop = "kimi-code-desktop";
    zcode = "zcode";
    kytyps5 = "kytyps5";
  };
in
{
  # Tools the aliases and initContent below rely on
  home.packages = with pkgs; [ eza bat ripgrep fastfetch ];

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      enter_accept = true;
      sync.records = true;
      update_check = false;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    plugins = [
      {
        name = "zsh-autosuggestions";
        src  = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src  = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
    ];

    # Only rebuild completion cache if older than 24 hours
    completionInit = ''
      autoload -Uz compinit
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      if [[ -n ''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump(#qN.mh+24) ]]; then
        compinit -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
      else
        compinit -C -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
      fi
    '';

    initContent = ''
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      ZSH_AUTOSUGGEST_USE_ASYNC=1

      if [[ -o interactive ]] && [[ -z "$NVIM" ]] && [[ "$TERM_PROGRAM" != "zed" ]]; then
        fastfetch
      fi

      nym() {
        case "$1" in
          update)
            ${packageUpdater}/bin/personal-package-update nym-vpnd "''${@:2}"
            ;;
          *)
            echo "Usage: nym update"
            return 1
            ;;
        esac
      }

      nix() {
        command nix "$@" || return $?
        if [[ $# -eq 2 && "$1" == flake && "$2" == update && "$PWD" -ef "$HOME/NixOS" ]]; then
          ${packageUpdater}/bin/personal-package-update all
        fi
      }
    '' + lib.concatStringsSep "\n" (lib.mapAttrsToList (command: package: ''
      ${command}() {
        if [[ "''${1-}" == update ]]; then
          shift
          ${packageUpdater}/bin/personal-package-update ${package} "$@"
        else
          command ${command} "$@"
        fi
      }
    '') updateCommands);

    sessionVariables = {
      BAT_PAGER = "";
    };

    shellAliases = {
      ls   = "eza";
      ll   = "eza -l";
      la   = "eza -la";
      tree = "eza --tree";
      cat  = "bat";
      fzf  = "sk";
      dua = "dua i";
      "g++" = "g++ -Wall -Wextra -Werror -std=c++20";
      gcc = "gcc -Wall -Wextra -Werror";
    };
  };
}
