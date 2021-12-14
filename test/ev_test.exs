defmodule EVTest do
  use EV.TestCase, async: true

  describe "publish/4" do
    test "should publish an event" do
      expect(PublisherMock, :call, fn changeset, _opts ->
        Ecto.Changeset.apply_action(changeset, :insert)
      end)

      assert {:ok, event} =
               EV.publish(%{a: 1, b: 2}, :event_happened, %{type: :system},
                 publisher: PublisherMock,
                 events: [event_happened: [version: 1]]
               )

      assert Map.take(event, [:payload, :type, :issuer, :version]) == %{
               type: :event_happened,
               payload: %{"a" => 1, "b" => 2},
               issuer: %{"type" => "system"},
               version: 1
             }
    end

    test "should return an error if event cannot be published" do
      expect(PublisherMock, :call, fn changeset, _opts ->
        changeset
        |> EV.Event.apply_changeset(%{published_at: nil})
        |> Ecto.Changeset.apply_action(:insert)
      end)

      assert {:error, changeset} =
               EV.publish(%{a: 1, b: 2}, :event_happened, %{type: :system},
                 publisher: PublisherMock,
                 events: [event_happened: [version: 1]]
               )

      assert not changeset.valid?
    end
  end

  describe "maybe_publish/4" do
    test "should publish an event" do
      expect(PublisherMock, :call, fn changeset, _opts ->
        Ecto.Changeset.apply_action(changeset, :insert)
      end)

      assert {:ok, event} =
               EV.maybe_publish({:ok, %{a: 1, b: 2}}, :event_happened, %{type: :system},
                 publisher: PublisherMock,
                 events: [event_happened: [version: 1]]
               )

      assert Map.take(event, [:payload, :type, :issuer, :version]) == %{
               type: :event_happened,
               payload: %{"a" => 1, "b" => 2},
               issuer: %{"type" => "system"},
               version: 1
             }
    end

    test "should return an error if event cannot be published" do
      expect(PublisherMock, :call, fn changeset, _opts ->
        changeset
        |> EV.Event.apply_changeset(%{published_at: nil})
        |> Ecto.Changeset.apply_action(:insert)
      end)

      assert {:error, changeset} =
               EV.publish({:ok, %{a: 1, b: 2}}, :event_happened, %{type: :system},
                 publisher: PublisherMock,
                 events: [event_happened: [version: 1]]
               )

      assert not changeset.valid?
    end

    test "should return an error if supplied payload is bad" do
      assert {:error, "bad payload"} =
               EV.maybe_publish({:error, "bad payload"}, :event_happened, %{type: :system},
                 publisher: PublisherMock,
                 events: [event_happened: [version: 1]]
               )
    end
  end
end
