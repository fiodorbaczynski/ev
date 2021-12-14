defmodule EV.Applicators.Default do
  @behaviour EV.Applicator

  @impl EV.Applicator
  def call(event, handler, _opts) do
    with {:ok, applied_event} <- mark_event_applied(event),
         {:ok, result} <- handler.(applied_event) do
      {:ok, {applied_event, result}}
    end
  end

  defp mark_event_applied(event) do
    event
    |> EV.Event.apply_changeset(%{applied_at: DateTime.utc_now()})
    |> Ecto.Changeset.apply_action(:update)
  end
end
