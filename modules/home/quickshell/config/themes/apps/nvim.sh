nvim_reload() {
  local cs="${C[nvim]}" bg=dark
  [ "${C[light]}" = true ] && bg=light
  local uid
  uid=$(id -u)
  for sock in $(find /run/user/"$uid" -maxdepth 3 -name "nvim.*" -type s 2>/dev/null); do
    nvim --server "$sock" \
      --remote-send ":set background=$bg | colorscheme $cs<CR>" \
      2>/dev/null || true
  done
}
