defmodule EV.Applicators.Default do
  @moduledoc """
  The default applicator.

  Simply uses `Ecto.Changeset.apply_action/2` to return an event based on the given changeset,
  and calls the handler function.

  ## Options

    * `:handler_opts` - optional; defaults to `nil`; passed as the second argument to the `handler/2` function.
  """

  @behaviour EV.Applicator

  @impl EV.Applicator
  def call(changeset, handler, opts) do
    handler_opts = EV.ConfigHelper.get_config(opts, :handler_opts, nil)

    with {:ok, applied_event} <- Ecto.Changeset.apply_action(changeset, :update),
         {:ok, result} <- handler.(applied_event, handler_opts) do
      {:ok, {applied_event, result}}
    end
  end
end
