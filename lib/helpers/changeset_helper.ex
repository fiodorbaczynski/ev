defmodule EV.ChangesetHelper do
  @spec apply_action(Ecto.Changeset.t()) :: {:ok, any()} | {:error, Ecto.Changeset.t()}
  def apply_action(changeset)

  def apply_action(%{valid?: true} = changeset) do
    {:ok, changeset |> get_changes() |> Jason.encode!() |> Jason.decode!()}
  end

  def apply_action(%{valid?: false} = changeset) do
    {:error, changeset}
  end

  defp get_changes(%Ecto.Changeset{data: data, changes: changes}) do
    changes
    |> Map.put_new(:id, data.id)
    |> get_changes()
  end

  defp get_changes(list) when is_list(list) do
    Enum.map(list, &get_changes(&1))
  end

  defp get_changes(map) when is_map(map) and not is_struct(map) do
    map
    |> Enum.map(fn {k, v} -> {k, get_changes(v)} end)
    |> Enum.into(%{})
  end

  defp get_changes(term), do: term
end
