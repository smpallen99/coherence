defmodule <%= web_base %>.Coherence.Mailer do
  @moduledoc false
  if Coherence.Config.mailer?() do
    use Swoosh.Mailer, otp_app: :coherence
  end
end
