#!/usr/bin/env bash
# Runs every automated check of the definition of done (AGENTS.md). CI runs this script unchanged,
# inside the project's development shell (flake.nix), which provides every tool used here. A Rust workspace's checks are below; add the project's own
# (its link checker, its dependency policy, its packaging) and keep this the one command that says
# whether the work is done.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step "format"
cargo fmt --all --check

step "lints"
cargo clippy --workspace --all-targets --locked -- -D warnings

step "build and tests"
cargo test --workspace --locked

step "documentation"
RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --locked

# With a deny.toml: licenses, advisories and sources (needs network access).
if [ -f deny.toml ]; then
    step "dependencies"
    cargo deny --locked check
fi

# The benchmarks that can run here, each failing when it exceeds its budget in docs/ROADMAP.md by
# more than its noise. Measurements that need the real hardware run by hand, and their figures go to
# docs/measurements.md.
if [ -x scripts/bench.sh ]; then
    step "benchmarks"
    scripts/bench.sh
fi

# Links between the Markdown files, offline; the development shell provides lychee.
step "links"
git ls-files -z '*.md' | xargs -0 lychee --offline --include-fragments --no-progress

step "all checks passed"
