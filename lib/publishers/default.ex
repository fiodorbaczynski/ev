defmodule EV.Publishers.Default do
  @moduledoc """
  The default publisher.

  Simply uses `Ecto.Changeset.apply_action/2` to return an event based on the given changeset.
  """

  @behaviour EV.Publisher

  @impl EV.Publisher
  def call(changeset, _opts) do
    Ecto.Changeset.apply_action(changeset, :insert)
  end
end
