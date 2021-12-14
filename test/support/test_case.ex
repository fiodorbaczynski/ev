defmodule EV.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox

      setup :verify_on_exit!
    end
  end
end
