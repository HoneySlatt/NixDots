{ config, pkgs, ... }:

let
  niri-single-column = pkgs.writeShellApplication {
    name = "niri-single-column";
    runtimeInputs = [ pkgs.jq config.programs.niri.package ];
    text = ''
      declare -A expanded

      sync_widths() {
        local id cols
        while read -r id cols; do
          if [[ $cols -eq 1 && -z ''${expanded[$id]:-} ]]; then
            niri msg action set-window-width --id "$id" 100%
            expanded[$id]=1
          elif [[ $cols -gt 1 && -n ''${expanded[$id]:-} ]]; then
            niri msg action set-window-width --id "$id" 50%
            unset "expanded[$id]"
          fi
        done < <(niri msg --json windows | jq -r '
          [.[] | select(.is_floating | not) | {id, ws: .workspace_id, col: .layout.pos_in_scrolling_layout[0]}]
          | group_by(.ws)[]
          | (map(.col) | unique | length) as $cols
          | .[] | "\(.id) \($cols)"')
      }

      sync_widths
      niri msg --json event-stream | while read -r event; do
        case $event in
          '{"WindowOpenedOrChanged"'* | '{"WindowClosed"'* | '{"WindowsChanged"'* | '{"WindowLayoutsChanged"'*)
            sync_widths
            ;;
        esac
      done
    '';
  };
in
{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "${niri-single-column}/bin/niri-single-column" ]; }
  ];
}
