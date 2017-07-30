
  alias <%= inspect schema.module %>

  @doc """
  Extracts the current `<%= inspect schema.module %>` from the `conn`.
  The API is identical to `Coherence.current_user/1`.
  ## Examples
      iex> current_<%= schema.singular %>()
      [%<%= inspect schema.alias %>{}, ...]
  """
  def current_<%= schema.singular %>(conn) do
    case Coherence.current_user(conn) do
      nil -> nil
      user ->
        map = Map.take(user, [<%= Enum.map_join([{:id, nil}, {:inserted_at, nil}, {:updated_at, nil} | schema.attrs], ", ", &inspect(elem(&1, 0))) %>])
        struct(User, map)
    end
  end

  @doc """
  Returns the list of <%= schema.plural %>.
  ## Examples
      iex> list_<%= schema.plural %>()
      [%<%= inspect schema.alias %>{}, ...]
  """
  def list_<%= schema.plural %> do
    Repo.all(<%= inspect schema.alias %>)
  end

  @doc """
  Gets a single <%= schema.singular %>.
  Raises `Ecto.NoResultsError` if the <%= schema.human_singular %> does not exist.
  ## Examples
      iex> get_<%= schema.singular %>!(123)
      %<%= inspect schema.alias %>{}
      iex> get_<%= schema.singular %>!(456)
      ** (Ecto.NoResultsError)
  """
  def get_<%= schema.singular %>!(id), do: Repo.get!(<%= inspect schema.alias %>, id)

  @doc """
  Updates a <%= schema.singular %>.
  ## Examples
      iex> update_<%= schema.singular %>(<%= schema.singular %>, %{field: new_value})
      {:ok, %<%= inspect schema.alias %>{}}
      iex> update_<%= schema.singular %>(<%= schema.singular %>, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a <%= inspect schema.alias %>.
  ## Examples
      iex> delete_<%= schema.singular %>(<%= schema.singular %>)
      {:ok, %<%= inspect schema.alias %>{}}
      iex> delete_<%= schema.singular %>(<%= schema.singular %>)
      {:error, %Ecto.Changeset{}}
  """
  def delete_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    Repo.delete(<%= schema.singular %>)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking <%= schema.singular %> changes.
  ## Examples
      iex> change_<%= schema.singular %>(<%= schema.singular %>)
      %Ecto.Changeset{source: %<%= inspect schema.alias %>{}}
  """
  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, %{})
end
