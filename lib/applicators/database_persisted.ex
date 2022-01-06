defmodule EV.Applicators.DatabasePersisted do
  @moduledoc """
  Persists applied events to a database in a transaction with the given handler.

  ## Options

    * `:repo` - full path `[:persistence_opts, :repo]`; required; module which defines the `Ecto.Repo` behavior;
      used for persistence
    * `:handler_opts` - optional; defaults to `nil`; passed as the second argument to the `handler/2` function.
  """

  @behaviour EV.Applicator

  @impl EV.Applicator
  def call(changeset, handler, opts) do
    repo = EV.ConfigHelper.fetch_config!(opts, :repo, :persistence_opts)
    handler_opts = EV.ConfigHelper.get_config(opts, :handler_opts, nil)

    repo.transaction(
      fn transaction ->
        with {:ok, applied_event} <- transaction.update(changeset, []),
             {:ok, result} <- handler.(applied_event, handler_opts) do
          {applied_event, result}
        else
          {:error, error} -> transaction.rollback(error)
        end
      end,
      []
    )
  end
end
