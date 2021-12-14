defmodule EV.Publisher do
  @moduledoc """
  Defines a behaviour for publishers.

  Publishers process events when published.
  One may, for example, persist given events to a database or otherwise inform another part
  of the application of the event.
  """

  @callback call(changeset :: Ecto.Changeset.t(), opts :: Keyword.t()) ::
              {:ok, EV.Event.t()} | {:error, any()}
end
