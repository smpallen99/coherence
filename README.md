# Coherence

Coherence is a full featured, configurable authentication system for Phoenix, with the following modules:

* Database Authenticatable: handles hashing and storing an encrypted password in the database.
* Invitable: sends invites to new users with a sign-up link, allowing the user to create their account with their own password.
* Registerable: allows anonymous users to register a users email address and password.
* Recoverable: provides a link to generate a password reset link with token expiry.
* Trackable: saves login statics like login counts, timestamps, and IP address for each user.
* Lockable: locks an account when a specified number of failed sign-in attempts has been exceeded.
* Unlockable With Token: provides a link to send yourself an unlock email.

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

## Customization

The coherence.install mix task generates a bunch of boiler plate code so you can easily customize the views, templates, and mailer.

Also, checkout the Coherence.Config module for a list of config items you can use to tune the behaviour of Coherence.

## License

`coherence` is Copyright (c) 2016 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.


