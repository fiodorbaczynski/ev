defmodule EV.Applicators.DatabasePersisted do
  @moduledoc """
  Persists applied events to a database in a transaction with the given handler.

  ## Options

    * `:repo` - full path `[:persistence_opts, :repo]`; required; module which defines the `Ecto.Repo` behavior;
      used for persistence
  """

  @behaviour EV.Applicator

  @impl EV.Applicator
  def call(changeset, handler, opts) do
    repo = EV.ConfigHelper.fetch_config!(opts, :repo, :persistence_opts)

    repo.transaction(
      fn transaction ->
        with {:ok, applied_event} <- transaction.update(changeset, []),
             {:ok, result} <- handler.(applied_event) do
          {applied_event, result}
        else
          {:error, error} -> transaction.rollback(error)
        end
      end,
      []
    )
  end
end
