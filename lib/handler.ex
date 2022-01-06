defmodule EV.Handler do
  @moduledoc """
  Defines a behaviour for event handlers.

  Handlers define how the system is supposed to react to events being applied.
  """

  @callback handle(event :: EV.Event.t(), opts :: any()) :: {:ok | :error, any()}
end
