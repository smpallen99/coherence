defmodule Coherence.Authentication.IpAddress do
  @moduledoc """
    Implements ip address based authentication. To use add

      plug Coherence.Authentication.IpAddress, allow: ~w(127.0.0.1 192.168.1.200)

    to your pipeline.

  IP addresses can be specified in a list as either IP or IP/subnet_mask, where subnet_mask
  can be an integer or dot format.

  If you would like access to the current user you must set each authorized IP address like:

      Coherence.CredentialStore.Server.put_credentials({127.0.0.1}, %{role: :admin})

  or use a custom store like:

      defmodule MyProject.Store do
        def get_user_data(ip) do
          Repo.one from u in User, where: u.ip_address == ^id
        end
      end

      plug Coherence.Authentication.IpAddress, allow: ~w(127.0.0.1 192.168.1.0/24), store: &MyProject.Store/1

  ## IP Format Examples:

      allow: ~w(127.0.0.1 192.169.1.0/255.255.255.0)
      allow: ~w(127.0.0.1 192.169.1.0/24)
      deny: ~w(10.10.0.0/16)

  ## Options

  * `:allow` - list of allowed IPs
  * `:deny` - list of denied IPs
  * `:error` - error to be displayed if the IP is not allowed
  * `:store` - the user_data store
  * `:assign_key` - the assigns key to store the user_data
  """

  @behaviour Plug
  use Bitwise

  import Plug.Conn
  import Coherence.Authentication.Utils

  alias Coherence.Authentication.Utils
  alias Coherence.Messages

  require Logger

  @dialyzer [
    {:nowarn_function, call: 2},
    # {:nowarn_function, get_auth_header: 1},
    # {:nowarn_function, verify_creds: 2},
    # {:nowarn_function, assert_creds: 4},
    {:nowarn_function, init: 1},
    # {:nowarn_function, halt_with_login: 3},
  ]

  @type t :: Ecto.Schema.t | Map.t
  @type conn :: Plug.Conn.t

  @doc """
    Add the credentials for a `token`. `user_data` can be any term but must not be `nil`.
  """
  @spec add_credentials(String.t, t, module) :: t
  def add_credentials(ip, user_data, store \\ Coherence.CredentialStore.Server) do
    store.put_credentials(ip, user_data)
  end

  @doc """
    Remove the credentials for a `token`.
  """
  @spec remove_credentials(String.t, module) :: t
  def remove_credentials(ip, store \\ Coherence.CredentialStore.Server) do
    store.delete_credentials(ip)
  end

  @spec init(Keyword.t) :: [tuple]
  def init(opts) do
    %{
      allow: Keyword.get(opts, :allow, []),
      deny: Keyword.get(opts, :deny, []),
      error: Keyword.get(opts, :error, Messages.backend().unauthorized_ip_address()),
      store: Keyword.get(opts, :store, Coherence.CredentialStore.Server),
      assign_key: Keyword.get(opts, :assign_key, :current_user),
    }
  end

  @spec call(conn, Keyword.t) :: conn
  def call(conn, opts) do
    ip = conn.peer |> elem(0)
    conn
    |> verify_ip(ip, opts)
    |> fetch_user_data(opts)
    |> assert_ip(opts)
  end

  defp verify_ip(conn, ip, %{allow: allow, deny: deny}), do: {conn, ip, in?(ip, allow) && !in?(ip, deny)}

  defp fetch_user_data({conn, ip, true}, %{store: store}), do: {conn, true, store.get_user_data(ip)}
  defp fetch_user_data({conn, _ip, valid?}, _), do: {conn, valid?, nil}

  defp assert_ip({conn, true, nil}, _), do: conn
  defp assert_ip({conn, true, user_data}, %{assign_key: assign_key}), do: assign(conn, assign_key, user_data)
  defp assert_ip({conn, _, _}, %{error: error}), do: halt_with_error(conn, error)

  defp in?(ip, list) do
    Enum.any? list, &(matches? String.split(&1, "/"), ip)
  end

  defp matches?([item], ip), do: Utils.to_string(ip) == item
  defp matches?([item, subnet], ip), do: in_subnet?(to_tuple(item), ip, subnet)

  defp subnet(string) when is_binary(string) do
    if String.contains?(string, ".") do
      string |> to_tuple |> subnet
    else
      string |> String.to_integer |> subnet
    end
  end
  defp subnet(num) when is_integer(num) do
    Enum.reduce(0..31, 0, &(if &1 < num, do: (&2 ||| 1) <<< 1, else: &2 <<< 1)) >>> 1
  end
  defp subnet(tuple) when is_tuple(tuple), do: to_integer(tuple)


  defp in_subnet?(source_ip, target_ip, subnet) do
    to_integer(source_ip) == (to_integer(target_ip) &&& subnet(subnet))
  end

  defp to_integer({a,b,c,d}) do
    a <<< 24 ||| b <<< 16 ||| c <<< 8 ||| d
  end

  defp to_tuple(string) when is_binary(string) do
    string
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end
end
