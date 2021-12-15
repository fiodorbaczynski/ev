defmodule EV.ConfigHelperTest do
  use EV.TestCase, async: false

  describe "fetch_config/3" do
    test "should fetch value at key from supplied opts" do
      assert {:ok, value} = EV.ConfigHelper.fetch_config([abc: "def"], :abc)

      assert value == "def"
    end

    test "should fetch value at keys path from supplied opts" do
      assert {:ok, value} = EV.ConfigHelper.fetch_config([abc: [def: "ghi"]], [:abc, :def])

      assert value == "ghi"
    end

    test "should fetch value at prefix ++ keys path from supplied opts" do
      assert {:ok, value} = EV.ConfigHelper.fetch_config([abc: [def: "ghi"]], :def, :abc)

      assert value == "ghi"
    end

    test "should fetch value at key from env" do
      Application.put_env(:ev, :abc, "def")

      assert {:ok, value} = EV.ConfigHelper.fetch_config([], :abc)

      assert value == "def"

      Application.delete_env(:ev, :abc)
    end

    test "should fetch value at keys path from env" do
      Application.put_env(:ev, :abc, def: "ghi")

      assert {:ok, value} = EV.ConfigHelper.fetch_config([], [:abc, :def])

      assert value == "ghi"

      Application.delete_env(:ev, :abc)
    end

    test "should fetch value at prefix ++ keys path from path" do
      Application.put_env(:ev, :abc, def: "ghi")

      assert {:ok, value} = EV.ConfigHelper.fetch_config([], :def, :abc)

      assert value == "ghi"
    end

    test "should return an error if given key doesn't exist" do
      assert EV.ConfigHelper.fetch_config([], :abc) == :error
    end

    test "should return an error if given key path doesn't exist" do
      assert EV.ConfigHelper.fetch_config([abc: []], [:abc, :def]) == :error
    end
  end

  describe "get_config/3" do
    test "should get value at key from supplied opts" do
      assert EV.ConfigHelper.get_config([abc: "def"], :abc) == "def"
    end

    test "should fetch value at keys path from supplied opts" do
      assert EV.ConfigHelper.get_config([abc: [def: "ghi"]], [:abc, :def]) == "ghi"
    end

    test "should fetch value at key from env" do
      Application.put_env(:ev, :abc, "def")

      assert EV.ConfigHelper.get_config([], :abc) == "def"

      Application.delete_env(:ev, :abc)
    end

    test "should fetch value at keys path from env" do
      Application.put_env(:ev, :abc, def: "ghi")

      assert EV.ConfigHelper.get_config([], [:abc, :def]) == "ghi"

      Application.delete_env(:ev, :abc)
    end

    test "should return nil if given key doesn't exist" do
      assert EV.ConfigHelper.get_config([], :abc) == nil
    end

    test "should return nil if given key path doesn't exist" do
      assert EV.ConfigHelper.get_config([abc: []], [:abc, :def]) == nil
    end
  end

  describe "fetch_config!/3" do
    test "should get value at key from supplied opts" do
      assert EV.ConfigHelper.fetch_config!([abc: "def"], :abc) == "def"
    end

    test "should fetch value at keys path from supplied opts" do
      assert EV.ConfigHelper.fetch_config!([abc: [def: "ghi"]], [:abc, :def]) == "ghi"
    end

    test "should fetch value at key from env" do
      Application.put_env(:ev, :abc, "def")

      assert EV.ConfigHelper.fetch_config!([], :abc) == "def"

      Application.delete_env(:ev, :abc)
    end

    test "should fetch value at keys path from env" do
      Application.put_env(:ev, :abc, def: "ghi")

      assert EV.ConfigHelper.fetch_config!([], [:abc, :def]) == "ghi"

      Application.delete_env(:ev, :abc)
    end

    test "should raise an error if given key doesn't exist" do
      assert_raise RuntimeError,
                   "`:abc` not configured or supplied as option for the application `:ev`.",
                   fn ->
                     EV.ConfigHelper.fetch_config!([], :abc) == nil
                   end
    end

    test "should raise an error if given key path doesn't exist" do
      assert_raise RuntimeError,
                   "`[:abc, :def]` not configured or supplied as option for the application `:ev`.",
                   fn ->
                     EV.ConfigHelper.fetch_config!([abc: []], [:abc, :def]) == nil
                   end
    end
  end
end
