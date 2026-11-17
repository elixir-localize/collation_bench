#!/usr/bin/env bash
# Builds romantic_collation's NIF without Nix: its Rust core (which has no
# dependencies, so cargo fetches nothing) and its C adapter, linked into
# romantic_nif/romantic_nif.so. Run it after `mix deps.get`.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source_dir=deps/romantic_collation
output_dir=romantic_nif

[[ -d $source_dir ]] || { echo "Run 'mix deps.get' first: $source_dir is missing" >&2; exit 1; }

# The crate declares rust-version 1.100; it builds on earlier compilers that
# support the 2024 edition, so the declared version is not enforced.
(cd "$source_dir/rust" && cargo build --release --offline --ignore-rust-version)

erts_include=$(erl -noshell -eval \
  'io:format("~s/erts-~s/include", [code:root_dir(), erlang:system_info(version)]), halt().')

case $(uname -s) in
  Darwin) link_flags=(-undefined dynamic_lookup) ;;
  *) link_flags=() ;;
esac

mkdir -p "$output_dir"
cc -O2 -fPIC -shared "${link_flags[@]}" \
  -I"$erts_include" -I"$source_dir/include" \
  "$source_dir/native/elixir_nif.c" \
  "$source_dir/rust/target/release/libromantic_collation.a" \
  -o "$output_dir/romantic_nif.so"

echo "Built $output_dir/romantic_nif.so. Set:"
echo "  export ROMANTIC_COLLATION_NIF=$PWD/$output_dir/romantic_nif"
