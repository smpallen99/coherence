defmodule Coherence.RememberableService do

  use Coherence.Config
  import Ecto.Query
  import Plug.Conn
  alias Coherence.Rememberable

  @doc """
  Delete a rememberable token.
  """
  @spec delete_rememberable(Plug.Conn.t, %{id: integer}) :: Plug.Conn.t
  def delete_rememberable(conn, %{id: id}) do
    if Config.has_option :rememberable do
      where(Rememberable, [u], u.user_id == ^id)
      |> Config.repo.delete_all
      conn
      |> delete_resp_cookie(Config.login_cookie)
    else
      conn
    end
  end

end
