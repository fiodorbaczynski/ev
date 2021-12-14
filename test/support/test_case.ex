defmodule EV.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import ExUnit.DocTest

      import Mox

      setup :verify_on_exit!
    end
  end
end
