Code.ensure_loaded Phoenix.Swoosh

defmodule Coherence.UserEmail do
  use Phoenix.Swoosh, view: Coherence.EmailView, layout: {Coherence.LayoutView, :email}
  alias Swoosh.Email
  require Logger

  def welcome(user) do
    %Email{}
    |> from(from_email)
    |> to(user.email)
    |> subject("Hello, Avengers!")
    |> render_body("welcome.html", %{username: user.email})
  end

  def password(user, url) do
    %Email{}
    |> from(from_email)
    |> to(user_email(user))
    |> add_reply_to
    |> subject("Reset password instructions")
    |> render_body("password.html", %{url: url, name: first_name(user.name)})
  end

  def confirmation(user, url) do
    %Email{}
    |> from(from_email)
    |> to(user_email(user))
    |> add_reply_to
    |> subject("Confirm your new account")
    |> render_body("confirmation.html", %{url: url, name: first_name(user.name)})
  end
  def invitation(invitation, url) do
    %Email{}
    |> from(from_email)
    |> to(user_email(invitation))
    |> add_reply_to
    |> subject("Invitation to create a new account")
    |> render_body("invitation.html", %{url: url, name: first_name(invitation.name)})
  end

  defp add_reply_to(mail) do
    case Coherence.Config.email_reply_to do
      nil     -> mail
      true    -> reply_to mail, from_email
      address -> reply_to mail, address
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

  defp from_email do
    case Coherence.Config.email_from do
      nil ->
        Logger.error ~s|Need to configure :coherence, :email_from, {"Name", "me@example.com"}|
        ""
      email -> email
    end
  end
end
