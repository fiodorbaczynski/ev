defmodule EV.ChangesetHelperTest do
  use EV.TestCase

  doctest EV.ChangesetHelper

  describe "get_changes/2" do
    test "should extract normalised nested changes from changeset" do
      assert EV.ChangesetHelper.get_changes(%Ecto.Changeset{
               valid?: true,
               data: %{},
               changes: %{
                 a: 1,
                 b: "2",
                 c: %{
                   c1: %Ecto.Changeset{valid?: true, data: %{}, changes: %{c11: "a", c12: "b"}},
                   c2: %Ecto.Changeset{valid?: true, data: %{}, changes: %{c21: "a", c22: "b"}}
                 },
                 d: [
                   %Ecto.Changeset{valid?: true, data: %{}, changes: %{d11: "a", d12: "b"}},
                   %Ecto.Changeset{valid?: true, data: %{}, changes: %{d21: "a", d22: "b"}}
                 ]
               }
             }) ==
               {:ok,
                %{
                  a: 1,
                  b: "2",
                  c: %{c1: %{c11: "a", c12: "b"}, c2: %{c21: "a", c22: "b"}},
                  d: [%{d11: "a", d12: "b"}, %{d21: "a", d22: "b"}]
                }}
    end

    test "should preserve carry fields from data" do
      assert EV.ChangesetHelper.get_changes(
               %Ecto.Changeset{
                 valid?: true,
                 data: %{guid: 1},
                 changes: %{
                   a: 1,
                   b: "2",
                   c: %{
                     c1: %Ecto.Changeset{
                       valid?: true,
                       data: %{guid: 2},
                       changes: %{c11: "a", c12: "b"}
                     },
                     c2: %Ecto.Changeset{
                       valid?: true,
                       data: %{guid: 3},
                       changes: %{c21: "a", c22: "b"}
                     }
                   },
                   d: [
                     %Ecto.Changeset{
                       valid?: true,
                       data: %{guid: 4},
                       changes: %{d11: "a", d12: "b", guid: 99}
                     },
                     %Ecto.Changeset{
                       valid?: true,
                       data: %{guid: 5},
                       changes: %{d21: "a", d22: "b"}
                     }
                   ]
                 }
               },
               carry_fields: :guid
             ) ==
               {:ok,
                %{
                  guid: 1,
                  a: 1,
                  b: "2",
                  c: %{c1: %{guid: 2, c11: "a", c12: "b"}, c2: %{guid: 3, c21: "a", c22: "b"}},
                  d: [%{guid: 99, d11: "a", d12: "b"}, %{guid: 5, d21: "a", d22: "b"}]
                }}
    end

    test "should preserve id by default" do
      assert EV.ChangesetHelper.get_changes(%Ecto.Changeset{
               valid?: true,
               data: %{id: 1},
               changes: %{
                 a: 1,
                 b: "2",
                 child: %Ecto.Changeset{valid?: true, data: %{id: 1}, changes: %{foo: "bar"}},
                 another_child: %Ecto.Changeset{
                   valid?: true,
                   data: %{id: 2},
                   changes: %{id: 3, bar: "baz"}
                 }
               }
             }) ==
               {:ok,
                %{
                  id: 1,
                  a: 1,
                  b: "2",
                  child: %{id: 1, foo: "bar"},
                  another_child: %{id: 3, bar: "baz"}
                }}
    end

    test "should base 64 encode unprintable binaries" do
      assert EV.ChangesetHelper.get_changes(%Ecto.Changeset{
               valid?: true,
               data: %{id: 1},
               changes: %{a: 1, b: "2", c: <<1, 2, 3>>}
             }) == {:ok, %{id: 1, a: 1, b: "2", c: "AQID"}}
    end
  end
end
