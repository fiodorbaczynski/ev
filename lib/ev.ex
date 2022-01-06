defmodule EV do
  @moduledoc """
  EV is a library for implementing events-based architecture.

  At a high level the goal is to split data processing and persistance (or API calls). An event is a standardised intermediary passed between these to steps.

  Suppose you have a function to create a user:

  ```elixir
  def create_user(params) do
    params
    |> User.changeset(params)
    |> Repo.insert()
  end
  ```

  Let's refactor this function using EV:

  ```elixir
  def create_user(params) do
    params
    |> User.new_changeset(params)
    |> EV.ChangesetHelper.get_changes()
    |> EV.maybe_publish(:user_created, nil)
    |> EV.maybe_apply()
  end

  @impl EV.Handler
  def handle(%{type: :user_created, payload: payload}, _opts) do
    payload
    |> User.changeset(params)
    |> Repo.insert()
  end
  ```

  Now if you call the `create_user/1` function you'll see something like this `{:ok, {%EV.Event{...} = _event, %User{...} = _user}}`.

  The event here is a struct which holds data such as type, payload, etc. Crucially, events hold all data necessary for the handler to execute its function.
  Here, this means a user can be created just from the event.

  While in this example the event was just returned alongside the user, the most basic usage would involve actually saving the event to a database.
  To achive this you can use the `EV.Publishers.DatabasePersisted` publisher, `EV.Applicators.DatabasePersisted` applicator,
  or write your own using the `EV.Publisher` and `EV.Applicator` behaviours, respectively.

  Let's now move on to tying it all together by discussing the event lifecycle.

  1. An event changeset is created with supplied data.
     ```elixir
     %Ecto.Changeset{..., changes: %{
       payload: %{...},
       issuer: %{...},
       version: 1,
       published_at: ~U[2022-01-06 18:09:39.218Z]
     }}
     ```
  2. The changeset is passed to the configured publisher for processing. This returns an event struct.
     ```elixir
     %EV.Event{
       payload: %{...},
       issuer: %{...},
       version: 1,
       published_at: ~U[2022-01-06 18:09:39.218Z]
     }
     ```
  3. The event is turned into a changeset again.
     ```elixir
     %Ecto.Changeset{..., data: %{
       payload: %{...},
       issuer: %{...},
       version: 1,
       published_at: ~U[2022-01-06 18:09:39.218Z]
     },
     changes: %{
       applied_at: ~U[2022-01-06 18:11:44.225Z]
     }}
     ```
  4. The event is passed to the configured applicator for processing.
     ```elixir
     %EV.Event{
       payload: %{...},
       issuer: %{...},
       version: 1,
       published_at: ~U[2022-01-06 18:09:39.218Z],
       applied_at: ~U[2022-01-06 18:11:44.225Z]
     }
     ```
  5. The event is passed to the handler.

  Steps 1-2. are triggered by `EV.publish/4` and `EV.maybe_publish/4`. Steps 3-4. are triggered by `EV.apply/2` and `EV.maybe_apply/2`.
  Step 5. is triggered from the applicator, but it's technically optional to call the handler at all.

  When using the `EV.Publishers.DatabasePersisted` publisher and `EV.Applicators.DatabasePersisted` applicator,
  steps 2. and 4. would be when the event is first saved and later updated (to include the `applied_at` date).

  ## Okay, but why?

  There are many benefits to this architecture, but here are some examples:

  1. Auditing. You can go through the history of your application's state to see what happened and who triggered it.
  2. Rollback/rollfarward. You can replicate the database state at any given point in time.
  3. Testing. You can replicate a part of a staging/production database (or even the whole thing) locally to test and debug.
  4. Asynchronous execution. You may opt to apply events asynchronously or in a background job.

  ## Configuration

  Everything can be configured either globally or by passing options to the releveant function(s). Explicitly passed options override global config.

  Some functions' options documentation includes a note "full path ...". This refers to the path when configuring this option globally.
  When passing options directly to the function you may use the short path.
  Take a look at the difference in `EV.ChangesetHelper.get_changes/2` configuration in the example below.

  Explicitly passed options are meant to override the global config and/or be used for testing and debugging. Configuring common options globally is prefered,
  especially for shared options.

  Your custom publishers and applicators can have their own options. To learn more see `EV.ConfigHelper`.

  ### Example

  With global config:

  ```elixir
  config :ev,
    publisher: EV.Publishers.DatabasePersisted,
    applicator: EV.Applicators.DatabasePersisted,
    events: [
      user_created: [version: 1, handler: &User.handle/2],
    ],
    persistence_opts: [
      repo: MyApp.Repo,
      table_name: "events",
      migration_version: "0.1.0"
    ],
    changeset_helper_opts: [
      carry_fields: [:id]
    ]

  def create_user(params) do
    params
    |> User.new_changeset(params)
    |> EV.ChangesetHelper.get_changes()
    |> EV.maybe_publish(:user_created, nil)
    |> EV.maybe_apply()
  end
  ```

  With supplied options:

  ```elixir
  def create_user(params) do
    params
    |> User.new_changeset(params)
    |> EV.ChangesetHelper.get_changes(carry_fields: [:id])
    |> EV.maybe_publish(
      :user_created,
      nil,
      publisher: EV.Publishers.DatabasePersisted,
      events: [
        user_created: [version: 1]
      ],
      persistence_opts: [repo: MyApp.Repo]
    )
    |> EV.maybe_apply(
      applicator: EV.Applicators.DatabasePersisted,
      events: [
        user_created: [handler: &User.handle/2]
      ],
      persistence_opts: [
        repo: MyApp.Repo,
        table_name: "events",
        migration_version: "0.1.0"
      ]
    )
  end
  ```

  ## Versioning

  Events must be versioned in order to avoid having invalid events.

  When a handler's logic changes the corresponding event should be given a version bump. The handler itself should be split into two function headers, each matching on the version.
  Alternatively, existing events can be migrated if possible.
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

  @doc """
  Applies an event. Calls supplied applicator.

  ## Options

    * `applicator` - optional; module used for the publication; see `EV.Applicator` for more details;
      defaults to `EV.Applicators.Default`; example values:
      * `EV.Applicators.Default` - returns the event without persisting it anywhere
      * `EV.Applicators.DatabasePersisted` - saves the event in a database, using `Ecto`;
        requires `:repo` to be supplied in `:publisher_opts`
    * `:events`
      * `event_type`
        * `:handler` - required; positive integer used as the event version

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
  @spec apply(event :: EV.Event.t(), opts :: Keyword.t()) :: {:ok | :error, any()}
  def apply(%{type: type} = event, opts \\ []) do
    applicator = EV.ConfigHelper.get_config(opts, :applicator, EV.Applicators.Default)

    handler = EV.ConfigHelper.fetch_config!(opts, [:events, type, :handler])

    event
    |> EV.Event.apply_changeset(%{applied_at: DateTime.utc_now()})
    |> applicator.call(handler, opts)
  end

  @doc """
  Applies an event only if given a tuple of `{:ok, event}`.

  For more details see `apply/2`.
  """
  @spec maybe_apply(maybe_event :: {:ok, EV.Event.t()} | {:error, any()}, opts :: Keyword.t()) ::
          {:ok | :error, any()}
  def maybe_apply(maybe_event, opts \\ [])

  def maybe_apply({:ok, event}, opts) do
    apply(event, opts)
  end

  def maybe_apply(error, _opts), do: error
end
