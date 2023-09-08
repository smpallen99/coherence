defmodule Coherence.RememberableService do
  @moduledoc false

  use Coherence.Config

  import Plug.Conn

  alias Coherence.Schemas

  require Logger
  @doc """
  Delete a rememberable token.
  """
  @spec delete_rememberable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete_rememberable(conn, %{id: id}) do
    if Config.has_option(:rememberable) do
      Rememberable
      |> Schemas.query_by(user_id: id)
      |> Schemas.delete_all()

      delete_resp_cookie(conn, Config.login_cookie())
    else
      conn
    end
  end

  def delete_rememberable(conn, user) do
    Logger.warning("user has no id #{inspect(user)}")
    conn
  end
end
