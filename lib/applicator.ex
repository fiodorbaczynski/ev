defmodule EV.Applicator do
  @moduledoc """
  Defines a behaviour for applicators.

  Applicators process events when applied. They should call the given handler.
  May also persist a given event to a database.
  """

  @callback call(
              changeset :: Ecto.Changeset.t(),
              handler :: (EV.Event.t(), any() -> {:ok | :error, any()}),
              opts :: Keyword.t()
            ) :: {:ok | :error, any()}
end
