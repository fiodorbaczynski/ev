defmodule EV.ChangesetHelper do
  @moduledoc """
  Helper meant for retrieving normalised changes from Ecto.Changeset.
  """

  @doc """
  Gets changes from a given changeset, recursively normalised.

  ## Options

    * `:carry_fields` - full_path [`:changeset_helper_opts`, :carry_fields]; optional; atom or list of atoms;
      specifies which, if any, fields should be taken from data when not present in changes; defaults to `[:id]`

  ## Examples

  ```elixir
  iex> changeset = %Ecto.Changeset{valid?: true, data: %{id: 1, foo: "abc"}, changes: %{foo: "cde", bar: "efg"}}
  iex> EV.ChangesetHelper.fetch_changes(changeset)
  {:ok, %{id: 1, foo: "cde", bar: "efg"}}

  iex> changeset = %Ecto.Changeset{valid?: true, data: %{id: 1, foo: "abc", baz: "123"}, changes: %{foo: "cde", bar: "efg"}}
  iex> EV.ChangesetHelper.fetch_changes(changeset, carry_fields: [:id, :baz])
  {:ok, %{id: 1, foo: "cde", bar: "efg", baz: "123"}}
  ```
  """
  @spec fetch_changes(Ecto.Changeset.t(), opts :: Keyword.t()) ::
          {:ok, any()} | {:error, Ecto.Changeset.t()}
  def fetch_changes(changeset, opts \\ [])

  def fetch_changes(%{valid?: true} = changeset, opts) do
    carry_fields =
      opts
      |> EV.ConfigHelper.get_config(:carry_fields, [:id], :changeset_helper_opts)
      |> List.wrap()

    {:ok, do_get_changes(changeset, carry_fields)}
  end

  def fetch_changes(%{valid?: false} = changeset, _opts) do
    {:error, changeset}
  end

  defp do_get_changes(%Ecto.Changeset{data: data, changes: changes}, carry_fields) do
    carry_fields
    |> Enum.reduce(changes, fn carried_field, acc ->
      case Map.fetch(data, carried_field) do
        {:ok, carried_field_value} -> Map.put_new(acc, carried_field, carried_field_value)
        :error -> acc
      end
    end)
    |> do_get_changes(carry_fields)
  end

  defp do_get_changes(list, carry_fields) when is_list(list) do
    Enum.map(list, &do_get_changes(&1, carry_fields))
  end

  defp do_get_changes(map, carry_fields) when is_map(map) and not is_struct(map) do
    map
    |> Enum.map(fn {k, v} -> {k, do_get_changes(v, carry_fields)} end)
    |> Enum.into(%{})
  end

  defp do_get_changes(binary, _carry_fields) when is_binary(binary) do
    if String.printable?(binary) do
      binary
    else
      Base.encode64(binary)
    end
  end

  defp do_get_changes(term, _carry_fields), do: term

  @spec cast_params!(map(), module()) :: map()
  def cast_params!(params, module) do
    fields = module.__schema__(:fields)

    module
    |> struct()
    |> Ecto.Changeset.cast(params, fields)
    |> Ecto.Changeset.apply_action!(:insert)
    |> Map.take(fields)
  end
end
