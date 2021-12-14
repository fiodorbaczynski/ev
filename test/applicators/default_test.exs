defmodule EV.Applicators.DefaultTest do
  use EV.TestCase, async: true

  describe "call/3" do
    setup do
      event =
        Ecto.Changeset.apply_action!(
          EV.Event.publish_changeset(%{
            type: :event_happened,
            version: 1,
            payload: %{a: 1, b: 2},
            issuer: %{type: :user, id: Ecto.UUID.generate()},
            published_at: DateTime.utc_now()
          }),
          :insert
        )

      {:ok, event: event}
    end

    test "should apply an event", %{event: %{payload: payload} = event} do
      expect(HandlerMock, :handle, fn %{payload: payload} ->
        {:ok, payload}
      end)

      assert {:ok, {applied_event, result}} =
               EV.Applicators.Default.call(event, &HandlerMock.handle/1, [])

      assert result == payload

      assert Map.take(applied_event, [:id, :type, :payload, :issuer, :version, :published_at]) ==
               Map.take(event, [:id, :type, :payload, :issuer, :version, :published_at])

      assert DateTime.diff(DateTime.utc_now(), applied_event.applied_at) <= 30
    end
  end
end
