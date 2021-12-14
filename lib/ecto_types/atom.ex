defmodule EV.EctoTypes.Atom do
  @moduledoc """
  The `Atom` Ecto type operates on atoms, but saves them as strings in the database

  Important note: this uses the unsafe function `String.to_atom/1`,
  and therefore should only be used on fields which have a constant range of available values,
  and which are most importantly *not* user-generated.
  """

  use Ecto.Type

  @impl Ecto.Type
  def type(), do: :string

  @impl Ecto.Type
  def cast(data)

  def cast(data) when is_atom(data) do
    {:ok, data}
  end

  def cast(data) when is_binary(data) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    {:ok, String.to_atom(data)}
  end

  def cast(_data), do: :error

  @impl Ecto.Type
  def load(data)

  def load(data) when is_binary(data) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    {:ok, String.to_atom(data)}
  end

  def load(_data), do: :error

  @impl Ecto.Type
  def dump(data)

  def dump(data) when is_atom(data) do
    {:ok, Atom.to_string(data)}
  end

  def dump(_data), do: :error
end
