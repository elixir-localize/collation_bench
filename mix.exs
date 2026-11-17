defmodule CollationBench.MixProject do
  use Mix.Project

  # The romantic_collation commit these benchmarks were written against.
  @romantic_collation_ref "0cf958291205b2cbdd8ae48a95ea372deaad7c8f"

  def project do
    [
      app: :collation_bench,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:benchee, "~> 1.5"},
      {:localize, "~> 1.7"},
      # Localize builds its ICU NIF with elixir_make, an optional dependency
      # the host lists.
      {:elixir_make, "~> 0.4", runtime: false},
      {:romantic_collation, github: "pmarreck/romantic_collation", ref: @romantic_collation_ref}
    ]
  end
end
