defmodule EV.Applicators.DatabasePersistedTest do
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
      RepoMock
      |> expect(:transaction, fn transaction_fun, _opts ->
        {:ok, transaction_fun.(RepoMock)}
      end)
      |> expect(:update, fn changeset, _opts ->
        Ecto.Changeset.apply_action(changeset, :update)
      end)

      expect(HandlerMock, :handle, fn %{payload: payload}, _opts ->
        {:ok, payload}
      end)

      assert {:ok, {applied_event, result}} =
               EV.Applicators.DatabasePersisted.call(changeset, &HandlerMock.handle/2,
                 repo: RepoMock
               )

      assert result == payload

      assert Map.take(applied_event, [:id, :type, :payload, :issuer, :version, :published_at]) ==
               Map.take(event, [:id, :type, :payload, :issuer, :version, :published_at])

      assert applied_event.applied_at == applied_at
    end

    test "should rollback if handler returns an error", %{changeset: changeset} do
      RepoMock
      |> expect(:transaction, fn transaction_fun, _opts ->
        transaction_fun.(RepoMock)
      end)
      |> expect(:update, fn changeset, _opts ->
        Ecto.Changeset.apply_action(changeset, :update)
      end)
      |> expect(:rollback, fn error ->
        {:error, error}
      end)

      expect(HandlerMock, :handle, fn _event, _opts ->
        {:error, "oops"}
      end)

      assert {:error, "oops"} =
               EV.Applicators.DatabasePersisted.call(changeset, &HandlerMock.handle/2,
                 repo: RepoMock
               )
    end

    test "should rollback if saving event fails", %{changeset: changeset} do
      RepoMock
      |> expect(:transaction, fn transaction_fun, _opts ->
        transaction_fun.(RepoMock)
      end)
      |> expect(:update, fn changeset, _opts ->
        changeset
        |> EV.Event.apply_changeset(%{applied_at: nil})
        |> Ecto.Changeset.apply_action(:update)
      end)
      |> expect(:rollback, fn error ->
        {:error, error}
      end)

      assert {:error, changeset} =
               EV.Applicators.DatabasePersisted.call(changeset, fn _ -> flunk() end,
                 repo: RepoMock
               )

      assert not changeset.valid?
    end
  end
end
