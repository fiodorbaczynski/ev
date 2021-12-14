defmodule EV.Publishers.DatabasePersisted do
  @behaviour EV.Publisher

  @impl EV.Publisher
  def call(changeset, opts) do
    repo = EV.ConfigHelper.fetch_config!(opts, [:publisher_opts, :repo])

    repo.insert(changeset, [])
  end
end
