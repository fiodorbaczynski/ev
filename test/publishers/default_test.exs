defmodule EV.Publishers.DefaultTest do
  use EV.TestCase, async: true

  describe "call/1" do
    setup do
      user_id = Ecto.UUID.generate()
      published_at = DateTime.utc_now()

      changeset =
        EV.Event.publish_changeset(%{
          type: :event_happened,
          version: 1,
          payload: %{a: 1, b: 2},
          issuer: %{type: :user, id: user_id},
          published_at: published_at
        })

      {:ok, user_id: user_id, published_at: published_at, changeset: changeset}
    end

    test "should properly cast an event changeset", %{
      user_id: user_id,
      published_at: published_at,
      changeset: changeset
    } do
      assert {:ok, %EV.Event{} = event} = EV.Publishers.Default.call(changeset, [])

      assert Map.take(event, [:type, :version, :payload, :issuer, :published_at]) == %{
               type: :event_happened,
               version: 1,
               payload: %{"a" => 1, "b" => 2},
               issuer: %{"type" => "user", "id" => user_id},
               published_at: published_at
             }
    end
  end
end
