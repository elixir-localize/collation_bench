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
      localize(),
      # Localize builds its ICU NIF with elixir_make, an optional dependency
      # the host lists.
      {:elixir_make, "~> 0.4", runtime: false},
      {:romantic_collation, github: "pmarreck/romantic_collation", ref: @romantic_collation_ref}
    ]
  end

  # Localize from hex, or with LOCALIZE_SOURCE=main from its main branch on
  # GitHub, to measure changes not yet released.
  defp localize do
    if System.get_env("LOCALIZE_SOURCE") == "main" do
      {:localize, github: "elixir-localize/localize", branch: "main"}
    else
      {:localize, "~> 1.8"}
    end
  end
end
