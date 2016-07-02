defmodule Coherence.ControllerHelpers do
  alias Coherence.Config

  def router_helpers do
    Module.concat(Config.module, Router.Helpers)
  end

  def logged_out_url(conn) do
    Config.logged_out_url || Module.concat(Config.module, Router.Helpers).session_path(conn, :new)
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def expired?(datetime, opts) do
    expire_on? = datetime
    |> Ecto.DateTime.to_erl
    |> Timex.DateTime.from_erl
    |> Timex.shift(opts)
    not Timex.before?(Timex.DateTime.now, expire_on?)
  end
end
