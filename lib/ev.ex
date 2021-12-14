defmodule EV do
  import Kernel, except: [apply: 2]

  @spec publish(payload :: map(), type :: atom(), issuer :: map() | nil, opts :: Keyword.t()) ::
          {:ok, Event.t()} | {:error, any()}
  def publish(payload, type, issuer, opts \\ []) do
    publisher = EV.ConfigHelper.get_config(opts, :publisher, EV.Publishers.Default)

    version = EV.ConfigHelper.fetch_config!(opts, [:events, type, :version])

    %{
      payload: payload,
      type: type,
      issuer: issuer,
      version: version,
      published_at: DateTime.utc_now()
    }
    |> EV.Event.publish_changeset()
    |> publisher.call(opts)
  end

  @spec maybe_publish(
          maybe_payload :: {:ok, map()} | {:error, any()},
          type :: atom(),
          issuer :: map() | nil,
          opts :: Keyword.t()
        ) :: {:ok, Event.t()} | {:error, any()}
  def maybe_publish(maybe_payload, type, issuer, opts \\ [])

  def maybe_publish({:ok, payload}, type, issuer, opts) do
    publish(payload, type, issuer, opts)
  end

  def maybe_publish(error, _type, _issuer, _opts), do: error

  @spec apply(event :: EV.Event.t(), opts :: Keyword.t()) :: {:ok | :error, any()}
  def apply(%{type: type} = event, opts \\ []) do
    applicator = EV.ConfigHelper.get_config(opts, :applicator, EV.Applicators.Default)

    handler = EV.ConfigHelper.fetch_config!(opts, [:events, type, :handler])

    applicator.call(event, &handler.handle/1, opts)
  end

  @spec maybe_apply(maybe_event :: {:ok, EV.Event.t()} | {:error, any()}, opts :: Keyword.t()) ::
          {:ok | :error, any()}
  def maybe_apply(maybe_event, opts \\ [])

  def maybe_apply({:ok, event}, opts) do
    apply(event, opts)
  end

  def maybe_apply(error, _opts), do: error
end
