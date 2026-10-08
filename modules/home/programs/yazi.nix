{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";

    settings = {
      opener.edit = [
        { run = "nvim %s"; desc = "Neovim"; "for" = "unix"; block = true; }
      ];

      mgr = {
        ratio = [ 1 4 3 ];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        show_hidden = false;
        show_symlink = true;
        scrolloff = 5;
        mouse_events = [ "click" "scroll" ];
        title_format = "Yazi: {cwd}";
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          on = "T";
          run = ''shell "$SHELL" --block'';
          desc = "Open shell in current directory";
        }
        {
          on = "<C-d>";
          run = ''shell "ripdrag $@ --and-exit" --confirm'';
          desc = "Drag and drop selected files";
        }
        {
          on = "f";
          run = ''shell 'file=$(fd --type f --hidden --follow --exclude .git | fzf --preview "bat --color=always --style=numbers {}"); [ -n "$file" ] && ya pub cd --str "$(dirname "$(realpath "$file")")"' --block --confirm'';
          desc = "fd + fzf: find and jump to file";
        }
      ];
    };
  };

  home.packages = [ pkgs.ripdrag ];
}

