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

### Against Localize's main branch

Set `LOCALIZE_SOURCE=main` to measure Localize's unreleased `main` branch instead of the hex release. Fetch and compile with it set, and run `MIX_ENV=prod mix deps.get` without it afterwards so that `mix.lock` returns to the hex release.

```bash
export LOCALIZE_SOURCE=main
```

## Reading the results

Both NIFs run on dirty CPU schedulers, so each NIF call includes the cost of moving to a dirty scheduler and back, which dominates for short strings. romantic_collation and Localize's ICU NIF (from Localize 1.8.0) sort in one NIF call with precomputed sort keys; Localize before 1.8.0 compared through the NIF, one call per comparison. Localize's Elixir collation builds sort keys.

The implementations do not order every pair alike:

* **Spanish and Romanian letters** — romantic_collation makes `ñ` and `ă`, `â`, `î`, `ș`, `ț` (with their cedilla forms) letters of their own after their base letter, so `año` sorts after `anzuelo`. CLDR treats them, as both treat accents such as `é`, `ô` or `ü`, as secondary differences, so `año` sorts first.

* **Latin letters it does not recognise** — such as `ą`, `ę`, `ő`, `ű`, `ť` and `ů` sort after `z` in code-point order in romantic_collation, and beside their base letter in CLDR.

* **Other scripts** — romantic_collation orders Greek, Cyrillic, kana and other non-Latin text by code point, so capitals sort before lower case and `Ё` before `А`, where CLDR folds case and orders each script's alphabet. Arabic, Hebrew, Devanagari, Han and Hangul letters come out in the same order in both in simple cases, since their code-point order is close to CLDR's.

* **Digits in other scripts and symbols** — romantic_collation reads only ASCII digits as numbers and sorts symbols and emoji after letters; CLDR with numeric ordering reads Arabic-Indic digits as numbers and sorts symbols first.

* **Punctuation** — romantic_collation orders it by code point, where CLDR groups it by kind.

## License

The benchmark code is released under the [Apache License 2.0](LICENSE.md). romantic_collation, a dependency, is MIT licensed.
