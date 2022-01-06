defmodule EV.Publisher do
  @moduledoc """
  Defines a behaviour for publishers.

  Publishers process events when applied.
  They may persist events to a database, or otherwise inform the system of the event.
  """

  @callback call(changeset :: Ecto.Changeset.t(), opts :: Keyword.t()) ::
              {:ok, EV.Event.t()} | {:error, any()}
end
