defmodule BoltexDbConnection.Mixfile do
  use Mix.Project

  def project do
    [app: :boltex_db_connection,
     version: "0.1.0",
     elixir: "~> 1.3 or ~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :db_connection]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:db_connection, "~> 1.1"},
      {:boltex, "~> 0.3.0"}
    ]
  end
end
