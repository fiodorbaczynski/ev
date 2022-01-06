defmodule EV.Event.Migration do
  @moduledoc """
  Generator for events table migrations.

  Migration templates can be found in `priv/migrations`.

  ## Options

  * `:table_name` - full path `[:persistence_opts, :table_name]` required; specifies the table name
  * `:migration_version` - full path `[:persistence_opts, :migration_version]`; optional;
    defaults to version specified in `mix.exs`; version of migration to be used

  ## Example

  ```elixir
  defmodule MyApp.Migrations.CreateApp do
    use Ecto.Migration
    use EV.Event.Migration, migration_version: "0.1.0"
  end
  ```
  """

  require Logger

  defmacro __using__(opts) do
    Application.ensure_loaded(:ev)

    {unquoted_opts, []} = Code.eval_quoted(opts)

    table_name = EV.ConfigHelper.fetch_config!(unquoted_opts, :table_name, :persistence_opts)

    migration_version =
      EV.ConfigHelper.get_config(
        unquoted_opts,
        :version,
        to_string(Application.spec(:ev, :vsn)),
        :persistence_opts
      )

    Logger.debug("Using #{table_name} as the events table")
    Logger.debug("Using #{migration_version} as the events migration version")

    migration =
      [:code.priv_dir(:ev), "migrations", "#{migration_version}.exs.eex"]
      |> Path.join()
      |> EEx.eval_file(assigns: [table_name: table_name])
      |> Code.string_to_quoted(
        warn_on_unnecessary_quotes: false,
        file: __CALLER__.file,
        line: __CALLER__.line
      )

    quote do
      @spec change() :: any()
      def change() do
        unquote(migration)
      end
    end
  end
end
