defmodule EV.MixProject do
  use Mix.Project

  def project do
    [
      app: :ev,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps() do
    [
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:jason, "~> 1.0"},
      {:ecto_sql, "~> 3.4"}
    ]
  end

  defp description() do
    """
    EV
    """
  end

  defp package() do
    [
      files: ["lib", "priv", "mix.exs", "README.md"],
      maintainers: ["Fiodor Baczyński"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/fiodorbaczynski/ev/",
        "Docs" => "https://hexdocs.pm/ev/"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]
end
