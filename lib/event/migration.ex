defmodule EV.Event.Migration do
  @moduledoc """
  Generator for events table migrations.
  """

  require Logger

  defmacro __using__(opts) do
    Application.ensure_loaded(:ev)

    {unquoted_opts, []} = Code.eval_quoted(opts)

    table_name = EV.ConfigHelper.fetch_config!(unquoted_opts, :table_name, :migration_opts)

    migration_version =
      EV.ConfigHelper.get_config(
        unquoted_opts,
        :version,
        to_string(Application.spec(:ev, :vsn)),
        :migration_opts
      )

    Logger.debug("Using #{table_name} as the events table")
    Logger.debug("Using #{migration_version} as the migration version")

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
