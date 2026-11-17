# Compares romantic_collation's NIF, ICU (through Localize's NIF) and
# Localize's Elixir collation, the last two with CLDR's und-u-kn (root order
# with numeric sorting), on strings of 5, 10, 20 and 50 code points.
#
#   LOCALIZE_NIF=true ROMANTIC_COLLATION_NIF=$PWD/romantic_nif/romantic_nif \
#     MIX_ENV=prod mix run bench/collation.exs

unless Localize.Nif.available?() do
  raise "Localize's ICU NIF is not loaded, so ICU cannot be measured. " <>
          "Build with LOCALIZE_NIF=true and an ICU 75+ installation."
end

lengths = [5, 10, 20, 50]
pair_count = 1_000
sort_size = 1_000

# Latin letters, accented letters, digits, a space and punctuation.
alphabet =
  String.graphemes("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") ++
    String.graphemes("éèêëàâäçñöôüùîïășțßÉÀÇÑÖÜ") ++
    String.graphemes("0123456789") ++ [" ", ".", "-", "_", ","]

:rand.seed(:exsss, {2026, 11, 17})

random_string = fn length ->
  1..length
  |> Enum.map(fn _ -> Enum.random(alphabet) end)
  |> Enum.join()
end

pairs = fn length ->
  for _ <- 1..pair_count, do: {random_string.(length), random_string.(length)}
end

compare_inputs = Map.new(lengths, fn length -> {"#{length} code points", pairs.(length)} end)

sort_inputs =
  Map.new(lengths, fn length ->
    {"#{length} code points", Enum.map(1..sort_size, fn _ -> random_string.(length) end)}
  end)

# Options resolved once. Localize also accepts a keyword list, resolved on
# every call; the "keyword options" job shows what that costs.
und_kn = Localize.Collation.Options.from_locale("und-u-kn")
icu = %{und_kn | backend: :nif}
elixir = %{und_kn | backend: :elixir}
icu_keywords = [locale: "und-u-kn", backend: :nif]

compare_all = fn compare ->
  fn pairs -> Enum.each(pairs, fn {a, b} -> compare.(a, b) end) end
end

# How often the orders agree, so a fast result is not a wrong one.
agreement_pairs = Enum.flat_map(Map.values(compare_inputs), & &1)

disagreements = fn left, right ->
  Enum.count(agreement_pairs, fn {a, b} -> left.(a, b) != right.(a, b) end)
end

romantic_compare = &RomanticCollation.compare/2
icu_compare = &Localize.Collation.compare(&1, &2, icu)
elixir_compare = &Localize.Collation.compare(&1, &2, elixir)

IO.puts("""
Order disagreements over #{length(agreement_pairs)} pairs:
  ICU vs Localize Elixir:      #{disagreements.(icu_compare, elixir_compare)}
  ICU struct vs keyword:       #{disagreements.(icu_compare, &Localize.Collation.compare(&1, &2, icu_keywords))}
  romantic vs ICU:             #{disagreements.(romantic_compare, icu_compare)}
""")

benchee_options = [warmup: 2, time: 5, memory_time: 0, print: [fast_warning: false]]

IO.puts("== #{pair_count} compares")

Benchee.run(
  %{
    "romantic_collation NIF" => compare_all.(romantic_compare),
    "ICU (Localize NIF)" => compare_all.(icu_compare),
    "Localize Elixir" => compare_all.(elixir_compare),
    "ICU (Localize NIF), keyword options" =>
      compare_all.(&Localize.Collation.compare(&1, &2, icu_keywords))
  },
  [inputs: compare_inputs] ++ benchee_options
)

IO.puts("== Sorting #{sort_size} strings")

Benchee.run(
  %{
    "romantic_collation NIF" => &RomanticCollation.sort/1,
    "ICU (Localize NIF)" => &Localize.Collation.sort(&1, icu),
    "Localize Elixir" => &Localize.Collation.sort(&1, elixir)
  },
  [inputs: sort_inputs] ++ benchee_options
)
