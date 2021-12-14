defmodule EV.ConfigHelper do
  @moduledoc """
  Helper meant for retrieving EV config by key or keys.

  Values supplied explicitly by argument take precedent.
  """

  @spec fetch_config(
          opts :: Keyword.t(),
          key_or_keys :: [atom()] | atom(),
          prefix :: [atom()] | atom()
        ) :: {:ok, any()} | :error
  def fetch_config(opts, key_or_keys, prefix \\ []) do
    keys = List.wrap(key_or_keys)
    prefix = List.wrap(prefix)
    all_keys = prefix ++ keys

    with :error <- do_fetch_config(opts, keys),
         :error <- do_fetch_env_config(all_keys) do
      :error
    end
  end

  @spec do_fetch_config(source :: Keyword.t(), keys :: [atom()]) :: {:ok, any()} | :error
  defp do_fetch_config(source, keys) do
    Enum.reduce_while(keys, {:ok, source}, fn key, {:ok, opts} ->
      opts
      |> Keyword.fetch(key)
      |> case do
        {:ok, opts} -> {:cont, {:ok, opts}}
        :error -> {:halt, :error}
      end
    end)
  end

  @spec do_fetch_env_config(keys :: [atom()]) :: {:ok, any()} | :error
  defp do_fetch_env_config([key | keys]) do
    :ev
    |> Application.fetch_env(key)
    |> case do
      {:ok, source} -> do_fetch_config(source, keys)
      :error -> :error
    end
  end

  @spec get_config(
          opts :: Keyword.t(),
          key_or_keys :: list(atom()) | atom(),
          default :: any(),
          prefix :: [atom()] | atom()
        ) :: any()
  def get_config(opts, key_or_keys, default \\ nil, prefix \\ []) do
    case fetch_config(opts, key_or_keys, prefix) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @spec fetch_config!(
          opts :: Keyword.t(),
          key_or_keys :: list(atom()) | atom(),
          prefix :: [atom()] | atom()
        ) :: any()
  def fetch_config!(opts, key_or_keys, prefix \\ []) do
    case fetch_config(opts, key_or_keys, prefix) do
      {:ok, value} ->
        value

      :error ->
        raise "`(#{inspect(List.wrap(prefix))}` ++ )#{inspect(List.wrap(key_or_keys))}` not configured or supplied as option for the application `:ev`."
    end
  end
end
