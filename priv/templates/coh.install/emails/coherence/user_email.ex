Code.ensure_loaded(Phoenix.Swoosh)

defmodule <%= web_base %>.Coherence.UserEmail do
  @moduledoc """
  Generate Coherence emails.

  Renders all the Coherence generated emails including:

  * Reset password
  * New account confirmation
  * Account Invitation
  * Account Unlock

  To assist in trouble shooting the mailer, or to retrieve email links like the
  confirmation or invitation emails, logging can be enabled. This feature is
  enabled by setting `log_emails: true` in the coherence's configuration.
  """
  use Phoenix.Swoosh,
    view: <%= web_base %>.Coherence.EmailView,
    layout: {<%= web_base %>.Coherence.LayoutView, :email}

  alias Swoosh.Email
  require Logger
  alias Coherence.Config
  import <%= web_base %>.Gettext

  defp site_name, do: Config.site_name(inspect(Config.module()))

  @doc """
  Render the reset password email.

  Renders the email sent when someone clicks the Forgot password link on the new
  pages. The email includes a link to reset the user's password.
  """
  def password(user, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(user))
    |> add_reply_to()
    |> subject(
      dgettext("coherence", "%{site_name} - Reset password instructions", site_name: site_name())
    )
    |> render_body("password.html", %{url: url, name: first_name(user.name)})
    |> log()
  end

  @doc """
  Renders the account confirmation email.

  Renders the email sent when someone registers for an account with the
  confirmable option enabled. The email contains a link to confirm the account.
  """
  def confirmation(user, url) do
    {template, subject, email} =
      if Config.get(:confirm_email_updates) && user.unconfirmed_email do
        {
          "reconfirmation.html",
          dgettext("coherence", "%{site_name} - Confirm your new email", site_name: site_name()),
          unconfirmed_email(user)
        }
      else
        {
          "confirmation.html",
          dgettext(
            "coherence",
            "%{site_name} - Confirm your new account",
            site_name: site_name()
          ),
          user_email(user)
        }
      end

    %Email{}
    |> from(from_email())
    |> to(email)
    |> add_reply_to()
    |> subject(subject)
    |> render_body(template, %{url: url, name: first_name(user.name)})
    |> log()
  end

  @doc """
  Renders the invitation email.

  Renders the email when someone is invited. The email contains a link to
  register for an account.
  """
  def invitation(invitation, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(invitation))
    |> add_reply_to()
    |> subject(
      dgettext(
        "coherence",
        "%{site_name} - Invitation to create a new account",
        site_name: site_name()
      )
    )
    |> render_body("invitation.html", %{url: url, name: first_name(invitation.name)})
    |> log()
  end

  @doc """
  Renders the unlock account email.

  Renders the email sent when a user requests to unlock their account. The email
  contains a link with an unlock token.
  """
  def unlock(user, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(user))
    |> add_reply_to()
    |> subject(
      dgettext("coherence", "%{site_name} - Unlock Instructions", site_name: site_name())
    )
    |> render_body("unlock.html", %{url: url, name: first_name(user.name)})
    |> log()
  end

  defp add_reply_to(mail) do
    case Coherence.Config.email_reply_to() do
      nil -> mail
      true -> reply_to(mail, from_email())
      address -> reply_to(mail, address)
    end
  end

  defp first_name(name) do
    case String.split(name, " ") do
      [first_name | _] -> first_name
      _ -> name
    end
  end

  defp user_email(user) do
    {user.name, user.email}
  end

  @doc false
  def unconfirmed_email(user) do
    {user.name, user.unconfirmed_email}
  end

  defp from_email do
    case Coherence.Config.email_from() do
      nil ->
        Logger.error(
          ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
        )

        nil

      {name, email} = email_tuple ->
        if is_nil(name) or is_nil(email) do
          Logger.error(
            ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
          )

          nil
        else
          email_tuple
        end
    end
  end

  @doc """
  Log a rendered email.
  """
  def log(%{html_body: body, subject: subject, from: from, to: to} = email) do
    if Application.get_env(:coherence, :log_emails) do
      Logger.info("Email to: #{inspect(to)}, from: #{inspect(from)}")
      Logger.info("Subject: #{subject}")
      Logger.info(body)
    end

    email
  end

  def log(email) do
    email
  end
end
