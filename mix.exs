defmodule Relax.Mixfile do
  use Mix.Project

  def project do
    [app: :relax,
     version: "0.3.0",
     elixir: "~> 1.0",
     package: package,
     description: description,
     deps: deps]
  end

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: applications(:all) ++ [:blacksmith]
  defp applications(_all),  do: [:logger]

  defp deps do
    [{:cowboy, "~> 1.0"},
     {:poison, "~> 1.0"},
     {:plug,   "~> 1.0"},
     {:ecto, "~> 1.0"},
     {:ja_serializer, "~> 0.3"},
     {:blacksmith, git: "git://github.com/batate/blacksmith.git", only: :test},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.7", only: :dev}]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/AgilionApps/relax"
      }
    ]
  end

  defp description do
    """
    A jsonapi.org serializer and optional server implementation in Elixir.

    Relax APIs are composed of a Router and Resources for handling requests, and
    complimented by JaSerializer for formatting responses.
    """
  end
end
