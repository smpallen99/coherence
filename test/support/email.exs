defmodule TestCoherenceWeb.Coherence.Email do
  defstruct [:from, :to, :subject, :reply_to, :template, :params]
end
defmodule TestCoherenceWeb.Coherence.Mailer do
  def deliver(email), do: email

end

defmodule TestCoherenceWeb.Coherence.UserEmail do
  defp site_name, do: Coherence.Config.site_name(inspect Coherence.Config.module)
  alias TestCoherenceWeb.Coherence.Email
  require Logger

  def password(user, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(user))
    |> add_reply_to
    |> subject("#{site_name()} - Reset password instructions")
    |> render_body("password.html", %{url: url, name: first_name(user.name)})
  end


  def confirmation(user, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(user))
    |> add_reply_to
    |> subject("#{site_name()} - Confirm your new account")
    |> render_body("confirmation.html", %{url: url, name: first_name(user.name)})
  end

  def invitation(invitation, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(invitation))
    |> add_reply_to
    |> subject("#{site_name()} - Invitation to create a new account")
    |> render_body("invitation.html", %{url: url, name: first_name(invitation.name)})
  end

  def unlock(user, url) do
    %Email{}
    |> from(from_email())
    |> to(user_email(user))
    |> add_reply_to
    |> subject("#{site_name()} - Unlock Instructions")
    |> render_body("unlock.html", %{url: url, name: first_name(user.name)})
  end

  defp from(email, from), do: Map.put(email, :from, from)
  defp to(email, to), do: Map.put(email, :to, to)
  defp reply_to(email, address), do: Map.put(email, :reply_to, address)
  defp subject(email, subject), do: Map.put(email, :subject, subject)
  defp render_body(email, template, params), do: struct(email, template: template, params: params)

  defp add_reply_to(mail) do
    case Coherence.Config.email_reply_to do
      nil     -> mail
      true    -> reply_to mail, from_email()
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
        Logger.error ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
        nil
      {name, email} = email_tuple ->
        if is_nil(name) or is_nil(email) do
          Logger.error ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
          nil
        else
          email_tuple
        end
    end
  end
end
