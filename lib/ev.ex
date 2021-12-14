defmodule EV do
  @moduledoc """
  Defines functions used to publish and apply events.
  """

  import Kernel, except: [apply: 2]

  @doc """
  Publishes an event. Calls supplied publisher.

  ## Options

    * `publisher` - optional; module used for the publication; see `EV.Publisher` for more details;
      defaults to `EV.Publishers.Default`; example values:
      * `EV.Publishers.Default` - returns the event without persisting it anywhere
      * `EV.Publishers.DatabasePersisted` - saves the event in a database, using `Ecto`;
        requires `:repo` to be supplied in `:publisher_opts`
    * `:events`
      * `event_type`
        * `:version` - required; positive integer used as the event version

  ## Examples

  ```elixir
  iex> {:ok, event} = EV.publish(%{a: 1, b: 2}, :something_happened, %{type: :system}, events: [something_happened: [version: 1]])
  iex> event.type
  :something_happened
  iex> event.version
  1
  iex> event.payload
  %{"a" => 1, "b" => 2}
  iex> event.issuer
  %{"type" => "system"}
  ```
  """
  @spec publish(payload :: map(), type :: atom(), issuer :: map() | nil, opts :: Keyword.t()) ::
          {:ok, EV.Event.t()} | {:error, any()}
  def publish(payload, type, issuer, opts \\ []) do
    publisher = EV.ConfigHelper.get_config(opts, :publisher, EV.Publishers.Default)
    publisher_opts = EV.ConfigHelper.get_config(opts, :publisher_opts, [])

    version = EV.ConfigHelper.fetch_config!(opts, [:events, type, :version])

    %{
      payload: payload,
      type: type,
      issuer: issuer,
      version: version,
      published_at: DateTime.utc_now()
    }
    |> EV.Event.publish_changeset()
    |> publisher.call(publisher_opts)
  end

  @doc """
  Publishes an event only if given a tuple of `{:ok, payload}`.

  For more details see `publish/4`.
  """
  @spec maybe_publish(
          maybe_payload :: {:ok, map()} | {:error, any()},
          type :: atom(),
          issuer :: map() | nil,
          opts :: Keyword.t()
        ) :: {:ok, EV.Event.t()} | {:error, any()}
  def maybe_publish(maybe_payload, type, issuer, opts \\ [])

  def maybe_publish({:ok, payload}, type, issuer, opts) do
    publish(payload, type, issuer, opts)
  end

  def maybe_publish(error, _type, _issuer, _opts), do: error

  @spec apply(event :: EV.Event.t(), opts :: Keyword.t()) :: {:ok | :error, any()}
  def apply(%{type: type} = event, opts \\ []) do
    applicator = EV.ConfigHelper.get_config(opts, :applicator, EV.Applicators.Default)
    applicator_opts = EV.ConfigHelper.get_config(opts, :applicator_opts, [])

    handler = EV.ConfigHelper.fetch_config!(opts, [:events, type, :handler])

    event
    |> EV.Event.apply_changeset(%{applied_at: DateTime.utc_now()})
    |> applicator.call(&handler.handle/1, applicator_opts)
  end

  @spec maybe_apply(maybe_event :: {:ok, EV.Event.t()} | {:error, any()}, opts :: Keyword.t()) ::
          {:ok | :error, any()}
  def maybe_apply(maybe_event, opts \\ [])

  def maybe_apply({:ok, event}, opts) do
    apply(event, opts)
  end

  def maybe_apply(error, _opts), do: error
end
