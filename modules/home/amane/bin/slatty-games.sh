# Installed games, as Slatty's library shows them; a game only Steam installed starts through Steam
slatty installs --json | jq '[.[] | {
  name: .title,
  art: (.cover // ""),
  launch: (if .steam_app then "xdg-open steam://rungameid/\(.steam_app)" else "slatty launch \(.id)" end)
}]'
