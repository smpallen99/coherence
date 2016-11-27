# Coherence

[![Build Status](https://travis-ci.org/smpallen99/coherence.png?branch=master)](https://travis-ci.org/smpallen99/coherence) [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[hex-img]: https://img.shields.io/hexpm/v/coherence.svg
[hex]: https://hex.pm/packages/coherence
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> <div style="font-color: red">Alert: Project under active development!</div>
>
> This is an early release. So expect changes and new features in the near future.

Checkout the [Coherence Demo Project](https://github.com/smpallen99/coherence_demo) to see an example project using Coherence.

Coherence is a full featured, configurable authentication system for Phoenix, with the following modules:

* [Database Authenticatable](#authenticatable): handles hashing and storing an encrypted password in the database.
* [Invitable](#invitable): sends invites to new users with a sign-up link, allowing the user to create their account with their own password.
* [Registerable](#registerable): allows anonymous users to register a users email address and password.
* [Confirmable](#confirmable): new accounts require clicking a link in a confirmation email.
* [Recoverable](#recoverable): provides a link to generate a password reset link with token expiry.
* [Trackable](#trackable): saves login statistics like login counts, timestamps, and IP address for each user.
* [Lockable](#lockable): locks an account when a specified number of failed sign-in attempts has been exceeded.
* [Unlockable With Token](#unlockable-with-token): provides a link to send yourself an unlock email.
* [Rememberable](#remember-me): provides persistent login with 'Remember me?' check box on login page.

Coherence provides flexibility by adding namespaced templates and views for only the options specified by the `mix coherence.install` command. This boiler plate code is added to your `web/templates/coherence` and `web/views/coherence` directories.

Once the boilerplate has been generated, you are free to customize the source as required.

As well, a `web/coherence_web.ex` is added. Migrations are also generated to add the required database fields.

See the [Docs](https://hexdocs.pm/coherence/Coherence.html) and [Wiki](https://github.com/smpallen99/coherence/wiki) for more information.

## Installation

  1. Add coherence to your list of dependencies in `mix.exs`:

        def deps do
          [{:coherence, "~> 0.3"}]
        end

  2. Ensure coherence is started before your application:

        def application do
          [applications: [:coherence]]
        end

## Upgrading

After upgrading a Coherence version, you should generate the boilerplate files. To assist this process, use the `--reinstall` option.

This option uses your project's existing coherence config and runs the the installer with the same options.

```shell
mix coherence.install --reinstall
```

Run a `git diff` to review the updated files. If you had updated any of the boilerplate files, you may need to manually integrate the changes into the newly generated files.

Run `mix help coherence.install` for more information.

## Getting Started

First, decide with modules you would like to use for your project. For the following example were are going to use a full install except for the confirmable option.

Run the installer

```bash
$ mix coherence.install --full-invitable
```

This will:

* add the coherence configuration to the end of your `config/config.exs` file.
* add a new User model if one does not already exist
* add migration files
  * timestamp_add_coherence_to_user.exs if the User model already exists
  * timestamp_create_coherence_user.exs if the User model does not exist
  * timestamp_create_coherence_invitable.exs
* add view files web/views/coherence/
* add template files to web/templates/coherence
* add email files to web/emails/coherence
* add web/coherence_web.ex file

You should review your `config/config.exs` as there are a couple items you will need to customize like email address and mail api_key. If you don't edit the email_from value to something different than it's default emails may not be sent.

See [Installer](#installer) for more install options.

You will need to update a few files manually.

```elixir
# web/router.ex

defmodule MyProject.Router do
  use MyProject.Web, :router
  use Coherence.Router         # Add this

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session  # Add this
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  # Add this block
  scope "/" do
    pipe_through :browser
    coherence_routes
  end

  # Add this block
  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end

  scope "/", MyProject do
    pipe_through :browser

    get "/", PageController, :index
    # add public resources below
  end

  scope "/", MyProject do
    pipe_through :protected

    # add protected resources below
    resources "/privates", MyProject.PrivateController
  end
end
```
**Important**: Note the name-spacing above. Unless you generate coherence controllers, ensure that the scopes, `scope "/" do`, do not include your projects' scope here. If so, the coherence routes will not work!

If the installer created a user model (one did not already exist), there is nothing you need to do with that generated file. Otherwise, update your existing model like this:

```elixir
# web/models/user.ex

defmodule MyProject.User do
  use MyProject.Web, :model
  use Coherence.Schema                                    # Add this

  schema "users" do
    field :name, :string
    field :email, :string
    coherence_schema                                      # Add this

    timestamps
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email] ++ coherence_fields)  # Add this
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_coherence(params)                         # Add this
  end
end
```

An alternative approach is add the authentication plugs to individual controllers that require authentication. You will want to use this approach if you require authentication for a subset of actions in a controller.

For example, lets say you want to show a list of products for everyone visiting the site, but only want authenticated users to be able to create, update, and delete products. You could do the following:

Ensure the following is in your `web/router.ex` file:

```elixir
  scope "/", MyProject do
    pipe_through :browser
    resources "/products", ProductController
  end
```

In your product controller add the following:

```elixir
defmodule MyProject.ProductController do
  use MyProject.Web, :controller

  plug Coherence.Authentication.Session, [protected: true] when action != :index

  # ...
```

## Option Overview

### Authenticatable

Handles hashing and storing an encrypted password in the database.

Provides `/sessions/new` and `/sessions/delete` routes for logging in and out with
the appropriate templates and view.

The following columns are added the `<timestamp>_add_coherence_to_user.exs` migration:

* :password_hash, :string - the encrypted password

### Invitable

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

### Registerable

Allows anonymous users to register a users email address and password.

Provides `/registrations/new`, `create`, `edit`, `update`, `show`, and `delete` routes for managing registrations.

Adds the following:

* `Register New Account` to the log-in page.
* `Link to account page on layout helpers`
* Show page with `edit` and `delete` links
* `edit` page

It is recommended that the :confirmable option is used with :registerable to
ensure a valid email address is captured.

### Confirmable

Requires a new account be confirmed. During registration, a confirmation token is generated and sent to the registering email. This link must be clicked before the user can sign-in.

Provides `edit` action for the `/confirmations` route.

The confirmation token expiry default of 5 days can be changed with the `:confirmation_token_expire_days` config entry.

### Recoverable

Allows users to reset their password using an expiring token send by email.

Provides `new`, `create`, `edit`, `update` actions for the `/passwords` route.

Adds a "Forgot your password?" link to the log-in form. When clicked, the user provides their email address and if found, sends a reset password instructions email with a reset link.

The expiry timeout can be changed with the `:reset_token_expire_days` config entry.

### Trackable

Saves login statistics like login counts, timestamps, and IP address for each user.

Adds the following database field to your User model with the generated migration:

```elixir
add :sign_in_count, :integer, default: 0  # how many times the user has logged in
add :current_sign_in_at, :datetime        # the current login timestamp
add :last_sign_in_at, :datetime           # the timestamp of the previous login
add :current_sign_in_ip, :string          # the current login IP adddress
add :last_sign_in_ip, :string             # the IP address of the previous login
```

### Lockable

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

### Unlockable with Token

Provides a link to send yourself an unlock email. When the user clicks the link, the user is presented a form to enter their email address and password. If the token has not expired and the email and password are valid, a unlock email is sent to the user's email address with an expiring token.

The default expiry time can be changed with the `:unlock_token_expire_minutes` config entry.

### Remember Me

The `rememberable` option provides persistent login when the 'Remember Me?' box is checked during login.

With this feature, you will automatically be logged in from the same browser when your current login session dies using a configurable expiring persistent cookie.

For security, both a token and series number stored in the cookie on initial login. Each new creates a new token, but preserves the series number, providing protection against fraud. As well, both the token and series numbers are hashed before saving them to the database, providing protection if the database is compromised.

The following defaults can be changed with the following config entries:

* :rememberable_cookie_expire_hours (2*24)
* :login_cookie                     ("coherence_login")

The following table is created by the generated `<timestamp>_create_coherence_rememberable.exs` migration:

```elixir
create table(:rememberables) do
  add :series_hash, :string
  add :token_hash, :string
  add :token_created_at, :datetime
  add :user_id, references(:users, on_delete: :delete_all)

  timestamps
end
create index(:rememberables, [:user_id])
create index(:rememberables, [:series_hash])
create index(:rememberables, [:token_hash])
create unique_index(:rememberables, [:user_id, :series_hash, :token_hash])
```

The `--rememberable` install option is not provided in any of the installer group options. You must provide the `--rememberable` option to install the migration and its support.

## Mix Tasks

### Installer

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
```

And some reinstall examples:

```bash
  # Reinstall with defaults (--silent --no-migrations --no-config --confirm-once)
  $ mix coherence.install --reinstall

  # Confirm to overwrite files, show instructions, and generate migrations
  $ mix coherence.install --reinstall --no-confirm-once --with-migrations
```

Run `$ mix help coherence.install` for more information.

### Clean

The following examples illustrate how to remove the files created by the installer:

```bash
  # Clean all the installed files
  $ mix coherence.clean --all

  # Clean only the installed view and template files
  $ mix coherence.clean --views --templates

  # Clean all but the models
  $ mix coherence.clean --all --no-models

  # Prompt once to confirm the removal
  $ mix coherence.clean --all --confirm-once
```

After installation, if you later want to remove one more options, here are a couple examples:

```bash
  # Clean one option
  $ mix coherence.clean --options=recoverable

  # Clean several options without confirmation
  $ mix coherence.clean --no-confirm --options="recoverable unlockable-with-token"

  # Test the uninstaller without removing files
  $ mix coherence.clean --dry-run --options="recoverable unlockable-with-token"
```

## Customization

The `coherence.install` mix task generates a bunch of boiler plate code so you can easily customize the views, templates, and mailer.

Also, checkout the Coherence.Config module for a list of config items you can use to tune the behaviour of Coherence.

### Custom Controllers

By default, controller boilerplate is not generated unless the `--controllers` option is provided to `mix coherence.install`.

The generated controllers are named `MyProject.Coherence.SessionController` as an example. Generated controllers are located in `web/controllers/coherence/`

If the controllers are generated, you will need to change your router to use the new names. For example:

```elixir
  # web/router.ex
  use MyProject.Web, :router
  use Coherence.Router

  # ...

  scope "/", MyProject do   # note the addition of MyProject
    pipe_through :public
    coherence_routes :public
  end

  scope "/", MyProject do   # note the addition of MyProject
    pipe_through :browser
    coherence_routes :private
  end
  # ...
end
```

### Customizing Routes

By default, Coherence assumes you want all available routes for the `opts` you've configured. However, you can specify which routes should be available by modifying your configuration.

For example, if you want all of the routes for `authenticatable`, but only the `new` and `create` actions from `registerable`:

```elixir
# config/config.exs
config :coherence,
  # ...
  opts: [:authenticatable, registerable: [:new, :create]]
```

### Customizing Redirections

Many of the controller actions redirect the user after create and update actions. These redirections can be customized by adding function call backs in the `web/controllers/redirect.ex` module that is generated by the `mix coherence.install` task.

For example, to have the user redirected to the login screen after logging out at the following:

```elixir
defmodule Coherence.Redirects do
  use Redirects
  import MyProject.Router.Helpers

  # override the log out action back to the log in page
  def session_delete(conn, _), do: redirect(conn, session_path(conn, :new))
end
```

See the documentation for further details.

### Customizing layout
By default coherence uses own layout from package, that can be installed to `web/templates/coherence/layout/app.html.eex`.

If you want to customize coherence controllers layout, you can follow different approaches:

* Edit layout at `web/templates/coherence/layout/app.html.eex`. In this case, unless authentication layout differs - you will get code duplication.

* Install coherence controllers to application and edit them, to use layout module different from `Coherence.LayoutView`

* Edit `web/views/coherence/layout_view.ex`:

  replace
```elixir
  use ContactDemo.Coherence.Web, :view
```
with
```elixir
  use Phoenix.View, root: "web/templates"
  # Import convenience functions from controllers
  import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

  # Use all HTML functionality (forms, tags, etc)
  use Phoenix.HTML

  import ContactDemo.Router.Helpers
  import ContactDemo.ErrorHelpers
  import ContactDemo.Gettext
  import ContactDemo.Coherence.ViewHelpers
```
This approach will require to move also all other coherence templates to top level templates directory `web/templates`

* And the last solution is to edit `web/coherence_web.ex` to allow it to setup which templates directory specific view should use:
```elixir
defmodule ExBlog.Coherence.Web do
  # add default coherence templates path
  @template_path "web/templates/coherence"

  # using default path unless user provides one explicitly
  def view(template_path \\ @template_path) do
    quote do
      use Phoenix.View, root: unquote(template_path)
      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import ExBlog.Router.Helpers
      import ExBlog.ErrorHelpers
      import ExBlog.Gettext
      import ExBlog.Coherence.ViewHelpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """

  #
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, args)
  end
  defmacro __using__([which | args]) do
    apply(__MODULE__, which, args)
  end
end
```
After that you can override templates directory for desired view module:

```elixir
defmodule Coherence.LayoutView do
  use ExBlog.Coherence.Web, [:view, "web/templates"]
  import ExBlog.LayoutView, only: [blog_header: 2, page_title: 1]
end
```

## Customizing User Changeset

The User model changeset used by Coherence can be customized for each Coherence controller. To customize the changeset, set the `changeset` config option.

For example, the following defines a changeset/3 function in your user model:

```elixir
  # config/config.exs
  config :coherence,
    # ...
    changeset: {MyProject.User, :changeset}
```

Now add a new `changeset/3` function to the user model. The following example defines a custom changeset for the registration controller:

```elixir
  # web/models/coherence/user.ex
  defmodule CoherenceDemo.User do
    use CoherenceDemo.Web, :model
    use Coherence.Schema

    # ...

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, [:name, :email] ++ coherence_fields)
      |> validate_required([:name, :email])
      |> validate_format(:email, ~r/@/)
      |> unique_constraint(:email)
      |> validate_coherence(params)
    end
    def changeset(model, params, :registration) do
      # custom changeset  for registration controller
      model
      |> cast(params, [:name, :email] ++ coherence_fields)
      |> validate_required([:name, :email])
      |> validate_format(:email, ~r/@/)
      |> unique_constraint(:email)
      |> validate_coherence(params)
    end
    def changeset(model, params, _which) do
      # use the default changeset for all other coherence controllers
      changeset model, params
    end
  end
```

When a custom changeset is configured, the changeset function is called with an atom indicating the controller calling the changeset, allowing you to match on specific controllers.

The list of controller actions are:

* :confirmation
* :invitation
* :password
* :registration
* :session
* :unlock

## Updating the User Model

During login, a current version of the user model is cashed in the credential store. During each authentication request, the user model is fetched from the credential store and placed in conn.assigns[:current_user] to avoid a database fetch on each request.

If the user model is changed after login, a call to `update_login` must be done to update the credential store. For example, in your controller update function, call:

```elixir
apply(Config.auth_module, Config.update_login, [conn, user, [id_key: Config.schema_key]])
```
to update the credential store.

This is not needed for registration update page.

## Configuring the Swoosh Email Adapter

The following configuration must be setup to send emails:

```elixir
config :coherence,
  email_from_name: "Some Name",
  email_from_email: "myname@domain.com"

config :coherence, CoherenceDemo.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "Add api key here"
```

You may want to configure the email system to use system environment variables.

```elixir
config :coherence,
  email_from_name: {:system, "NAME"},
  email_from_email: {:system, "EMAIL"}

config :coherence, CoherenceDemo.Coherence.Mailer,
  api_key: {:system, "API_KEY"}
```

## Authentication

Currently Coherence supports three modes of authentication including HTTP Basic, Session, and Token authentication.

For HTTP Basic and Token authentication, you will need to add the credentials into the Credential Store. This is not required for Session or IpAddress Authentication.

IpAddress authentication is a good solution for server to server rest APIs.

### Add HTTP Basic Credentials Example

```elixir
creds = Coherence.Authentication.Basic.encode_credentials("Admin", "SecretPass")
Coherence.CredentialStore.Agent.put_credentials(creds, %{role: :admin})
```

### Add Token Credentials Example

```elixir
token = Coherence.Authentication.Token.generate_token
Coherence.CredentialStore.Agent.put_credentials(token, %{role: :admin})
```

### Add IP Credentials Example

```elixir
Coherence.CredentialStore.Agent.put_credentials({127.0.0.1}, %{role: :admin})
```

IpAddress authentication does not require this step. Its optional. If the user_data
is not found in the credential store, the conn.assigns will not be set.

To add authentication, use on of the following three:

### HTTP Basic Plug Example

```elixir
plug Coherence.Authentication.Basic, realm: "Secret"
```

The realm parameter is optional and can be omitted. By default "Restricted Area" will be used as realm name. You can also pass the error parameter, which should be a string or a function. If a string is passed, that string will be sent instead of the default message "HTTP Authentication Required" on authentication failure (with status code 401). If a function is passed, that function will be called with one argument, `conn`.

### Token Plug Example

```elixir
plug Coherence.Authentication.Token, source: :params, param: "auth_token", error: ~s'{"error":"authentication required"}'
```

The error parameter is optional and is treated as in the example above. The source parameter defines how to retrieve the token from the connection. Currently, the three acceptable values are: `:params`, `:header` and `:session`. Their name is self-explainatory. The param parameter defines the name of the parameter/HTTP header/session key where the token is stored. This should cover most cases, but if retrieving the token is more complex than that, you can pass a tuple for the source parameter. The tuple must be in the form `{MyModule, :my_function, ["param1", 42]}`. The function must accept a connection as its first argument (which will be injected as the head of the given parameter list) and any other number of parameters, which must be given in the third element of the tuple. If no additional arguments are needed, an empty list must be given.

### Session Plug Example

```elixir
plug Coherence.Authentication.Session, cookie_expire: 10*60*60, login: &MyController.login/1, assigns_key: :authenticated_user
```

The `:cookie_expire` value the expire time in seconds. The `:login` is a fun that will be passed `conn` if the user is not logged in. Use the `:assigns_key` to change the default `:current_user` value.

Note that if you provide a login callback, that you must return `halt conn` a the end of the function.

### IP Address Plug Example

```elixir
plug Coherence.Authentication.IpAddress, allow: ~w(127.0.0.1 192.168.1.0/24)
plug Coherence.Authentication.IpAddress, allow: ~w(0.0.0.0/0), deny: ~w(127.0.0.1)
```

The first example will allow local host and any ip address in the subnet 192.168.1.0/255.255.255.0

The second example allows any ip except for localhost.

## Authorization

Coherence is a user management and authentication solution. Support for authorization (access control) can be achieved using another package like [Canary](https://github.com/cpjk/canary).

For an example of using [Canary](https://github.com/cpjk/canary) with Coherence, please visit the [CoherenceDemo canary branch](https://github.com/smpallen99/coherence_demo/tree/canary).

## Contributing

We appreciate any contribution to Coherence. Check our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [CONTRIBUTING.md](CONTRIBUTING.md) guides for more information. We usually keep a list of features and bugs [in the issue tracker][1].

## References

* Detailed Example [Coherence Demo](https://github.com/smpallen99/coherence_demo)
* [Docs](https://hexdocs.pm/coherence/)

  [1]: https://github.com/smpallen99/coherence/issues

## License

`coherence` is Copyright (c) 2016 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.

Much of the authentication code was taken from [PlugAuth](https://github.com/bitgamma/plug_auth), Copyright (c) 2014, Bitgamma OÜ <opensource@bitgamma.com>
