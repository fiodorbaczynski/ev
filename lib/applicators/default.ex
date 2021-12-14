defmodule EV.Applicators.Default do
  @moduledoc """
  The default applicator.

  Simply uses `Ecto.Changeset.apply_action/2` to return an event based on the given changeset,
  and calls the handler function.
  """

  @behaviour EV.Applicator

  @impl EV.Applicator
  def call(changeset, handler, _opts) do
    with {:ok, applied_event} <- Ecto.Changeset.apply_action(changeset, :update),
         {:ok, result} <- handler.(applied_event) do
      {:ok, {applied_event, result}}
    end
  end
end
