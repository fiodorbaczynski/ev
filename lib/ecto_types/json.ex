defmodule EV.EctoTypes.JSON do
  @moduledoc """
  The `JSON` Ecto type behaves like the built-in `:map` type,
  except it stringifies keys when cast.

  This is important for consistency regardless of whether a given record is saved to the database.
  Since maps are represented as json in databases, the keys will be stringified if saved.
  """

  use Ecto.Type

  @impl Ecto.Type
  def type(), do: :jsonb

  @impl Ecto.Type
  def cast(data) do
    with {:ok, encoded} <- Jason.encode(data),
         {:ok, decoded} <- Jason.decode(encoded) do
      {:ok, decoded}
    else
      _error -> :error
    end
  end

  @impl Ecto.Type
  def load(data)

  def load(data) when is_binary(data) do
    data
    |> Jason.decode()
    |> case do
      {:ok, decoded} -> {:ok, decoded}
      _error -> :error
    end
  end

  def load(_data), do: :error

  @impl Ecto.Type
  def dump(data) do
    data
    |> Jason.encode()
    |> case do
      {:ok, encoded} -> {:ok, encoded}
      _error -> :error
    end
  end
end
