defmodule PhoenixOauth2Provider.Mixfile do
  use Mix.Project

  @version "0.5.0"

  def project do
    [app: :phoenix_oauth2_provider,
     version: @version,
     elixir: "~> 1.6",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:phoenix] ++ Mix.compilers,
     preferred_cli_env: [credo: :test, ex_doc: :test],
     deps: deps(),

     # Hex
     description: "The fastest way to set up OAuth 2.0 server in your Phoenix app",
     package: package(),

      # Docs
      name: "PhoenixOauth2Provider",
      docs: [source_ref: "v#{@version}", main: "PhoenixOauth2Provider",
             canonical: "http://hexdocs.pm/phoenix_oauth2_provider",
             source_url: "https://github.com/danschultzer/phoenix_oauth2_provider",
             extras: ["README.md"]]
   ]
  end

  def application do
    [extra_applications: extra_applications(Mix.env)]
  end

  defp extra_applications(:test), do: [:postgrex, :ecto, :logger]
  defp extra_applications(_), do: [:logger]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # {:ex_oauth2_provider, "~> 0.4.4"},
      {:ex_oauth2_provider, github: "danschultzer/ex_oauth2_provider"},
      {:gettext, ">= 0.13.0"},
      {:phoenix, "~> 1.4"},

      {:ecto_sql, "~> 3.0.0", only: [:test]},
      {:plug_cowboy, "~> 2.0", only: [:test]},
      {:phoenix_ecto, "~> 4.0", only: [:test, :dev]},
      {:phoenix_html, "~> 2.13.0", only: [:test, :dev]},
      {:postgrex, ">= 0.14.0", only: :test},
      {:credo, "~> 0.10", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Dan Shultzer", "Benjamin Schultzer"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/danschultzer/phoenix_oauth2_provider"},
      files: ~w(lib priv/boilerplate priv/gettext) ++ ~w(LICENSE mix.exs README.md)
    ]
  end
end
