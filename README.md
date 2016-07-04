# Coherence

Coherence is a full featured, configurable authentication system for Phoenix, with the following modules:

* [Database Authenticatable](#authenticatable): handles hashing and storing an encrypted password in the database.
* [Invitable](#invitable): sends invites to new users with a sign-up link, allowing the user to create their account with their own password.
* [Registerable](#registerable): allows anonymous users to register a users email address and password.
* [Recoverable](#recoverable): provides a link to generate a password reset link with token expiry.
* [Trackable](#trackable): saves login statics like login counts, timestamps, and IP address for each user.
* [Lockable](#lockable): locks an account when a specified number of failed sign-in attempts has been exceeded.
* [Unlockable With Token](#unlockable): provides a link to send yourself an unlock email.

Coherence provides flexibility by adding namespaced templates and views for only the options specified by the `mix coherence.install` command. This boiler plate code is added to your `web/templates/coherence` and `web/views/coherence` directories.

Once the boilerplate has been generated, you free to customize the source as required.

As well, a `web/coherence_web.ex` is added. Migrations are also generated to add the required database fields.

## Installation

  1. Add coherence to your list of dependencies in `mix.exs`:

        def deps do
          [{:coherence, github: "smpallen99/coherence"}]
        end

  2. Ensure coherence is started before your application:

        def application do
          [applications: [:coherence]]
        end

## Getting Started

First, decide with modules you would like to use for your project. For the following example were are going to use a full install except for the registerable option.

Run the installer

```bash
$ mix coherence.install --full-invitable
```

This will add the coherence configuration to the end of your `config/config.exs` file. Please review this file as there are a couple items you will need to customize like email address and mail api_key.

See [Installer](#installer) for more install options.

You will need to update a few files manually.

```elixir
# web/router.ex

defmodule MyProject.Router do
  use MyProject.Web, :router
  use Coherence.Router         # Add this

  pipeline :browser do
    plug :accepts, ["html"]
    # ...
    plug Coherence.Authentication.Database, db_model: MyProject.User  # Add this
  end

  pipeline :public do
    plug :accepts, ["html"]
    # ...
    plug Coherence.Authentication.Database, db_model: MyProject.User, login: false  # Add this
  end

  scope "/" do
    pipe_through :public
    coherence_routes :public     # Add this
  end

  scope "/" do
    pipe_through :browser
    coherence_routes :private    # Add this
  end
  # ...
end
```

Update your user model like:

```elixir
# web/models/user.ex

defmodule MyProject.User do
  use MyProject.Web, :model
  use Coherence.Schema     # Add this

  schema "users" do
    field :name, :string
    field :email, :string
    coherence_schema       # Add this

    timestamps
  end

  @required_fields ~w(name email)
  @optional_fields ~w() ++ coherence_fields   # Add this

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_coherence(params)             # Add this
  end
end
```

## Options Descriptions

### <a name="authenticatable"></a>Authenticatable

Handles hashing and storing an encrypted password in the database.

Provides `/sessions/new` and `/sessions/delete` routes for logging in and out with
the appropriate templates and view.

The following columns are added the `<timestamp>_add_coherence_to_user.exs` migration:

* :encrypted_password, :string - the encrypted password

### <a name="invitable"></a>Invitable

Handles sending invites to new users with a sign-up link, allowing the user to create their account with their own password.

Provides `/invitations/new` and `invitations/edit` routes for creating a new invitation and creating a new account from the invite email.

These routes can be configured to require login by using the `coherence_routes :private` macro in your router.exs file.

Invitation token timeout will be added in the future.

The following table is created by the generated `<timestamp>_create_coherence_invitable.exs` migration:

```elixir
create table(:invitations) do
  add :name, :string
  add :email, :string
  add :token, :string
end
```

### <a name="registerable"></a>Registerable

Allows anonymous users to register a users email address and password.

Provides `/registrations/new` and `/registrations/create` routes for creating a new registration.

Adds a `Register New Account` to the log-in page.

It is recommended that the :confirmable option is used with :registerable to
ensure a valid email address is captured.

### <a name="recoverable"></a>Recoverable

Allows users to reset their password using an expiring token send by email.

Provides `new`, `create`, `edit`, `update` actions for the `/passwords` route.

Adds a "Forgot your password?" link to the log-in form. When clicked, the user provides their email address and if found, sends a reset password instructions email with a reset link.

The expiry timeout can be changed with the `:reset_token_expire_days` config entry.

### <a name="trackable"></a>Trackable

Saves login statics like login counts, timestamps, and IP address for each user.

Adds the following database field to your User model with the generated migration:

```elixir
add :sign_in_count, :integer, default: 0  # how many times the user has logged in
add :current_sign_in_at, :datetime        # the current login timestamp
add :last_sign_in_at, :datetime           # the timestamp of the previous login
add :current_sign_in_ip, :string          # the current login IP adddress
add :last_sign_in_ip, :string             # the IP address of the previous login
```

### <a name="lockable"></a>Lockable

Locks an account when a specified number of failed sign-in attempts has been exceeded.

The following defaults can be changed with the following config entries:

* `:unlock_timeout_minutes`
* `:max_failed_login_attempts`

Adds the following database field to your User model with the generated migration:

```elixir
add :failed_attempts, :integer, default: 0
add :unlock_token, :string
add :locked_at, :datetime
```

### <a name="unlockable"></a>Unlockable with Token

Provides a link to send yourself an unlock email. When the user clicks the link, the user is presented a form to enter their email address and password. If the token has not expired and the email and password are valid, a unlock email is sent to the user's email address with an expiring token.

The default expiry time can be changed with the `:unlock_token_expire_minutes` config entry.

## <a name="installer"></a>Installer

The following examples illustrate various configuration scenarios for the install mix task:

```bash
    # Install with only the `authenticatable` option
    $ mix coherence.install

    # Install all the options except `confirmable` and `invitable`
    $ mix coherence.install --full

    # Install all the options except `invitable`
    $ mix coherence.install --full-confirmable

    # Install all the options except `confirmable`
    $ mix coherence.install --full-invitable

    # Install the `full` options except `lockable` and `trackable`
    $ mix coherence.install --full --no-lockable --no-trackable

    # Remove all the coherence generated boilerplate files
    $ mix coherence.install --clean
```

Run `$ mix help coherence.install` for more information.

## Customization

The `coherence.install` mix task generates a bunch of boiler plate code so you can easily customize the views, templates, and mailer.

Also, checkout the Coherence.Config module for a list of config items you can use to tune the behaviour of Coherence.

## License

`coherence` is Copyright (c) 2016 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.


