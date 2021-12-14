defmodule EV.Applicators.DatabasePersisted do
  @behaviour EV.Applicator

  @impl EV.Applicator
  def call(event, handler, opts) do
    repo = EV.ConfigHelper.fetch_config!(opts, [:applicator_opts, :repo])

    repo.transaction(
      fn transaction ->
        with {:ok, {applied_event, result}} <- EV.Applicators.Default.call(event, handler, opts),
             {:ok, applied_event} <- transaction.update(applied_event, []) do
          {:ok, {applied_event, result}}
        else
          {:error, error} -> transaction.rollback(error)
        end
      end,
      []
    )
  end
end
