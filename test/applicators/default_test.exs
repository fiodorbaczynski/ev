defmodule EV.Applicators.DefaultTest do
  use EV.TestCase, async: true

  describe "call/3" do
    setup do
      applied_at = DateTime.utc_now()

      event =
        Ecto.Changeset.apply_action!(
          EV.Event.publish_changeset(%{
            type: :something_happened,
            version: 1,
            payload: %{a: 1, b: 2},
            issuer: %{type: :user, id: Ecto.UUID.generate()},
            published_at: DateTime.utc_now()
          }),
          :insert
        )

      changeset = EV.Event.apply_changeset(event, %{applied_at: applied_at})

      {:ok, event: event, changeset: changeset, applied_at: applied_at}
    end

    test "should apply an event", %{
      event: %{payload: payload} = event,
      changeset: changeset,
      applied_at: applied_at
    } do
      expect(HandlerMock, :handle, fn %{payload: payload}, _opts ->
        {:ok, payload}
      end)

      assert {:ok, {applied_event, result}} =
               EV.Applicators.Default.call(changeset, &HandlerMock.handle/2, [])

      assert result == payload

      assert Map.take(applied_event, [:id, :type, :payload, :issuer, :version, :published_at]) ==
               Map.take(event, [:id, :type, :payload, :issuer, :version, :published_at])

      assert applied_event.applied_at == applied_at
    end
  end
end
