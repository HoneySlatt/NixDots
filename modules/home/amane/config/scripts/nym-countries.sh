#!/usr/bin/env bash
set -euo pipefail

nymvpnc="/run/current-system/sw/bin/nym-vpnc"
jq_bin="/etc/profiles/per-user/honey/bin/jq"

if [ ! -x "$jq_bin" ]; then
  jq_bin="jq"
fi

constraints="$("$nymvpnc" gateway get 2>/dev/null || true)"
entry="$(sed -n 's/^Entry point: Country.*"\([A-Z][A-Z]\)".*/\1/p' <<< "$constraints")"
exit_country="$(sed -n 's/^Exit point: Country.*"\([A-Z][A-Z]\)".*/\1/p' <<< "$constraints")"
state="$("$nymvpnc" status 2>/dev/null | sed -n 's/^State: \([A-Za-z]*\).*/\1/p' || true)"

# Location is counted from the right since gateway names may contain "|"; it looks like "Paris [FR]"
"$nymvpnc" gateway list wg --table-style markdown 2>/dev/null \
  | awk -F'|' 'NR > 3 && match($(NF - 5), /\[[A-Z][A-Z]\]/) { print substr($(NF - 5), RSTART + 1, 2) }' \
  | "$jq_bin" -R -n \
      --arg entry "$entry" \
      --arg exit "$exit_country" \
      --arg state "${state:-Unknown}" \
      --slurpfile iso "$NYM_ISO_3166" '
    ($iso[0]."3166-1" | map({ (.alpha_2): (.common_name // .name) }) | add) as $names
    | {
        state: $state,
        entry: $entry,
        exit: $exit,
        countries: (
          [inputs] | group_by(.) | map({
            code: .[0],
            name: ($names[.[0]] // .[0]),
            servers: length,
            entry: (.[0] == $entry),
            exit: (.[0] == $exit)
          })
          | sort_by(.name)
        )
      }
  '
