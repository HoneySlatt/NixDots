# The shared theme dispatcher also updates the parallel Noctalia/Umbriel session.
switch_noctalia() {
  if command -v noctalia-desktop >/dev/null 2>&1; then
    noctalia-desktop sync
  fi
}
