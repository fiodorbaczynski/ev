defmodule EV.Applicator do
  @callback call(event :: EV.Event.t(), handler :: module(), opts :: Keyword.t()) ::
              {:ok | :error, any()}
end
