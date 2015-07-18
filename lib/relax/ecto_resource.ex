defmodule Relax.EctoResource do
  use Behaviour

  @moduledoc """
  A DSL to help build JSONAPI resource endpoints.
  """

  ###
  # TODO:
  #  * Move as much out of macros and into shared code as possible.
  #  * Refactor all the things.
  #  * Add documentation
  #  * Add delete support
  #  * Consider adding a "records" function
  #  * Consider adding default implimentation of each action.
  #  * Add /relationship support?

  defmacro __using__(opts) do
    plug_module = case opts[:plug] do
      nil      -> Plug.Builder
      :builder -> Plug.Builder
      :router  -> Plug.Router
    end

    quote location: :keep do
      use unquote(plug_module)
      use Relax.Responders
      @behaviour Relax.EctoResource

      import Relax.EctoResource, only: [resource: 2, resource: 1]

      # Fetch and parse JSONAPI params
      plug Plug.Parsers, parsers: [Relax.PlugParser]

      # Set parent as param if nested
      plug :nested_relax_resource

      def nested_relax_resource(conn, _opts) do
        case {conn.private[:relax_parent_name], conn.private[:relax_parent_id]} do
          {nil, _}   -> conn
          {_, nil}   -> conn
          {name, id} ->
            new = %{"filter" => Map.put(%{}, name, id)}
            merged = Dict.merge conn.query_params, new, fn(_k, v1, v2) ->
              Dict.merge(v1, v2)
            end
            Map.put(conn, :query_params, merged)
        end
      end

      def relax_resource(conn, _opts) do
        do_resource(conn, conn.method, conn.path_info)
      end

      @before_compile Relax.EctoResource
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      # If nothing matches, next plug
      def do_resource(conn, _, _), do: conn
    end
  end

  @doc """
  Defines the Module using Ecto.Model to be exposed by this resource.
  """
  defcallback model() :: Atom

  @doc """
  Defines the Module using Ecto.Repo to be queried by this resource.
  """
  defcallback repo() :: Atom

  @doc """
  Filters the JSONAPI attributes and relationships based on keyword list
  """
  def filter_attributes(%Plug.Conn{params: p}, opts) do
    relationships = Enum.reduce opts[:relationships] || [], %{}, fn(r, acc) ->
      key = Atom.to_string(r)
      val = p["data"]["relationships"][key]["data"]["id"]
      Dict.put(acc, key <> "_id", val)
    end

    p["data"]["attributes"]
    |> Dict.take(Enum.map(opts[:attributes], &Atom.to_string/1))
    |> Dict.merge(relationships)
  end

  defmacro resource(type) do
    Relax.EctoResource.use_type(type, [])
  end

  defmacro resource(type, opts) do
    Relax.EctoResource.use_type(type, opts)
  end

  def use_type(:fetch_all, opts) do
    quote do: use(Relax.EctoResource.FetchAll, unquote(opts))
  end

  def use_type(:fetch_one, opts) do
    quote do: use(Relax.EctoResource.FetchOne, unquote(opts))
  end

  def use_type(:create, opts) do
    quote do: use(Relax.EctoResource.Create, unquote(opts))
  end

  def use_type(:update, opts) do
    quote do: use(Relax.EctoResource.Update, unquote(opts))
  end
end