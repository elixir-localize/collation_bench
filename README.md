# Collation benchmarks

Benchee benchmarks of three collation implementations on strings of 5, 10, 20 and 50 code points: the [romantic_collation](https://github.com/pmarreck/romantic_collation) NIF, ICU through [Localize](https://hex.pm/packages/localize)'s NIF, and Localize's pure-Elixir collation. ICU and Localize sort with CLDR's `und-u-kn`, the root collation with numeric ordering, which is the CLDR collation nearest to romantic_collation's.

## What is measured

* **Compares** — 1,000 `compare/3` calls on random pairs, for each string length.

* **Sorts** — sorting 1,000 random strings, for each string length.

* **Agreement** — before timing, the number of pairs each implementation orders differently, so a fast result is not mistaken for a correct one.

The strings mix Latin letters, accented letters, digits, a space and punctuation, from a fixed random seed, so every run measures the same data. Localize is timed with its options resolved once; the "keyword options" job also shows the cost of resolving a keyword list on every call.

## Requirements

* **Elixir 1.17+ on Erlang/OTP 26+**, with `json_polyfill` added on OTP 26 as Localize requires.

* **ICU 75 or later** — on macOS, `brew install icu4c`. Localize's NIF is built against it.

* **A Rust toolchain and a C compiler** — romantic_collation's own build uses Nix; `build_romantic_nif.sh` builds the same NIF with `cargo` and `cc` instead.

## Running

```bash
MIX_ENV=prod mix deps.get
```

```bash
./build_romantic_nif.sh
```

```bash
export LOCALIZE_NIF=true ROMANTIC_COLLATION_NIF=$PWD/romantic_nif/romantic_nif
```

```bash
MIX_ENV=prod mix run bench/collation.exs
```

The benchmark stops before timing anything if Localize's ICU NIF is not loaded, since Localize would otherwise fall back to its Elixir collation and report it as ICU.

## Reading the results

Both NIFs run on dirty CPU schedulers, so each NIF call includes the cost of moving to a dirty scheduler and back, which dominates for short strings. romantic_collation sorts with precomputed sort keys, one NIF call per list; Localize's ICU sort compares through the NIF, one call per comparison, while its Elixir sort builds sort keys.

The implementations do not order every pair alike. romantic_collation treats each accented letter as a letter of its own after its base letter, so `ñ` sorts after every word in `n`, where CLDR treats accents as secondary differences that decide only between otherwise equal strings. It also orders punctuation by code point, where CLDR groups it by kind.

## License

The benchmark code is released under the [Apache License 2.0](LICENSE.md). romantic_collation, a dependency, is MIT licensed.
