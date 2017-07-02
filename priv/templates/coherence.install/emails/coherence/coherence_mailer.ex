defmodule <%= base %>.Coherence.Mailer do
  @moduledoc false
  if Config.mailer?() do
    use Swoosh.Mailer, otp_app: :coherence
  end
end
