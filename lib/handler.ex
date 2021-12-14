defmodule EV.Handler do
  @callback handle(event :: EV.Event.t()) :: {:ok | :error, any()}
end
