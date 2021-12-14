defmodule EV.Publishers.Default do
  @behaviour EV.Publisher

  @impl EV.Publisher
  def call(changeset, _opts) do
    Ecto.Changeset.apply_action(changeset, :insert)
  end
end
