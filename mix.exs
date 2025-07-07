defmodule Angela.MixProject do
  use Mix.Project

  def project do
    [
      app: :angela,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Angela.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_gram, "~> 0.55"},
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.12"},
      {:jason, ">= 1.0.0"},

      # Dev dependencies
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      # {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo, github: "rrrene/credo", only: [:dev, :test], runtime: false, override: true},
      {:assert_match, "~> 1.0", only: [:test]}
    ]
  end
end
