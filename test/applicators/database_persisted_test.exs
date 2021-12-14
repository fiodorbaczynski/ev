defmodule EV.Applicators.DatabasePersistedTest do
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
      RepoMock
      |> expect(:transaction, fn transaction_fun, _opts ->
        transaction_fun.(RepoMock)
      end)
      |> expect(:update, fn applied_event, _opts ->
        {:ok, applied_event}
      end)

      expect(HandlerMock, :handle, fn %{payload: payload} ->
        {:ok, payload}
      end)

      assert {:ok, {applied_event, result}} =
               EV.Applicators.DatabasePersisted.call(event, &HandlerMock.handle/1,
                 applicator_opts: [repo: RepoMock]
               )

      assert result == payload

      assert Map.take(applied_event, [:id, :type, :payload, :issuer, :version, :published_at]) ==
               Map.take(event, [:id, :type, :payload, :issuer, :version, :published_at])

      assert DateTime.diff(DateTime.utc_now(), applied_event.applied_at) <= 30
    end

    test "should rollback if handler returns an error", %{event: event} do
      RepoMock
      |> expect(:transaction, fn transaction_fun, _opts ->
        transaction_fun.(RepoMock)
      end)
      |> expect(:rollback, fn error ->
        {:error, error}
      end)

      expect(HandlerMock, :handle, fn _event ->
        {:error, "oops"}
      end)

      assert {:error, "oops"} =
               EV.Applicators.DatabasePersisted.call(event, &HandlerMock.handle/1,
                 applicator_opts: [repo: RepoMock]
               )
    end

    test "should rollback if saving event fails", %{event: event} do
      RepoMock
      |> expect(:transaction, fn transaction_fun, _opts ->
        transaction_fun.(RepoMock)
      end)
      |> expect(:update, fn applied_event, _opts ->
        {:error, EV.Event.apply_changeset(applied_event, %{applied_at: nil})}
      end)
      |> expect(:rollback, fn error ->
        {:error, error}
      end)

      expect(HandlerMock, :handle, fn %{payload: payload} ->
        {:ok, payload}
      end)

      assert {:error, changeset} =
               EV.Applicators.DatabasePersisted.call(event, &HandlerMock.handle/1,
                 applicator_opts: [repo: RepoMock]
               )

      assert not changeset.valid?
    end
  end
end
