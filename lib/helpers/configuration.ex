defmodule EV.ConfigHelper do
  @spec fetch_config(opts :: Keyword.t(), key_or_keys :: [atom()] | atom()) ::
          {:ok, any()} | :error
  def fetch_config(opts, key_or_keys)

  def fetch_config(opts, [_key | _rest] = keys) do
    with :error <- do_fetch_config(opts, keys),
         :error <- do_fetch_env_config(keys) do
      :error
    end
  end

  def fetch_config(opts, key) do
    fetch_config(opts, [key])
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

  @spec get_config(opts :: Keyword.t(), key_or_keys :: list(atom()) | atom(), default :: any()) ::
          any()
  def get_config(opts, key_or_keys, default \\ nil) do
    case fetch_config(opts, key_or_keys) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @spec fetch_config!(opts :: Keyword.t(), key_or_keys :: list(atom()) | atom()) ::
          any()
  def fetch_config!(opts, key_or_keys) do
    case fetch_config(opts, key_or_keys) do
      {:ok, value} ->
        value

      :error ->
        raise "`#{inspect(key_or_keys)}` not configured for the application `:ev` or supplied as option."
    end
  end
end
