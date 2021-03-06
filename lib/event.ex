defmodule EV.Event do
  @moduledoc """
  Defines an `Ecto.Schema` for events.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{
          id: Ecto.UUID.t(),
          type: atom(),
          version: pos_integer(),
          payload: map(),
          issuer: map() | nil,
          published_at: DateTime.t(),
          applied_at: DateTime.t() | nil
        }
  @primary_key {:id, :binary_id, autogenerate: true}
  schema EV.ConfigHelper.get_config([], :table_name, "events", :persistence_opts) do
    field(:type, EV.EctoTypes.Atom)
    field(:version, :integer)
    field(:payload, EV.EctoTypes.JSON)
    field(:issuer, EV.EctoTypes.JSON)
    field(:published_at, :utc_datetime_usec)
    field(:applied_at, :utc_datetime_usec)
  end

  @doc false
  @spec publish_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def publish_changeset(event \\ %__MODULE__{}, params) do
    event
    |> cast(params, [:type, :version, :payload, :issuer, :published_at])
    |> put_change(:id, Ecto.UUID.generate())
    |> validate_required([:type, :version, :payload, :published_at])
    |> validate_number(:version, greater_than: 0)
  end

  @doc false
  @spec apply_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def apply_changeset(event \\ %__MODULE__{}, params) do
    event
    |> cast(params, [:applied_at])
    |> validate_required([:id, :type, :version, :payload, :published_at, :applied_at])
    |> validate_number(:version, greater_than: 0)
  end
end
