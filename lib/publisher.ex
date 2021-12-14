defmodule EV.Publisher do
  @callback call(changeset :: Ecto.Changeset.t(), opts :: Keyword.t()) ::
              {:ok, EV.Event.t()} | {:error, any()}
end
