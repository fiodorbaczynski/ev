defmodule EV.Publishers.DatabasePersisted do
  @moduledoc """
  Persists published events to a database.

  ## Options

    * `:repo` - full path `[:persistence_opts, :repo]`; required; module which defines the `Ecto.Repo` behavior;
      used for persistence
  """

  @behaviour EV.Publisher

  @impl EV.Publisher
  def call(changeset, opts) do
    repo = EV.ConfigHelper.fetch_config!(opts, :repo, :persistence_opts)

    repo.insert(changeset, [])
  end
end
