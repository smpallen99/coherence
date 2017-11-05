defmodule <%= base %>.Coherence.Schemas do

  use Coherence.Config

  import Ecto.Query

  @user_schema Config.user_schema
  @repo        Config.repo

  def list_user do
    @repo.all @user_schema
  end

  def list_by_user(opts) do
    @repo.all query_by(@user_schema, opts)
  end

  def get_by_user(opts) do
    @repo.get_by @user_schema, opts
  end

  def get_user(id) do
    @repo.get @user_schema, id
  end

  def get_user!(id) do
    @repo.get! @user_schema, id
  end

  def get_user_by_email(email) do
    @repo.get_by @user_schema, email: email
  end

  def change_user(struct, params) do
    @user_schema.changeset struct, params
  end

  def change_user(params) do
    @user_schema.changeset @user_schema.__struct__, params
  end

  def change_user do
    @user_schema.changeset @user_schema.__struct__, %{}
  end

  def create_user(params) do
    @repo.insert change_user(params)
  end

  def create_user!(params) do
    @repo.insert! change_user(params)
  end

  def update_user(user, params) do
    @repo.update change_user(user, params)
  end

  def update_user!(user, params) do
    @repo.update! change_user(user, params)
  end

  Enum.each <%= schema_list %>, fn module ->

    name =
      module
      |> Module.split
      |> List.last
      |> String.downcase

    def unquote(String.to_atom("list_#{name}"))() do
      @repo.all unquote(module)
    end

    def unquote(String.to_atom("list_#{name}"))(%Ecto.Query{} = query) do
      @repo.all query
    end

    def unquote(String.to_atom("list_by_#{name}"))(opts) do
      @repo.all query_by(unquote(module), opts)
    end

    def unquote(String.to_atom("get_#{name}"))(id) do
      @repo.get unquote(module), id
    end

    def unquote(String.to_atom("get_#{name}!"))(id) do
      @repo.get! unquote(module), id
    end

    def unquote(String.to_atom("get_by_#{name}"))(opts) do
      @repo.get_by unquote(module), opts
    end

    def unquote(String.to_atom("change_#{name}"))(struct, params) do
      unquote(module).changeset(struct, params)
    end

    def unquote(String.to_atom("change_#{name}"))(params) do
      unquote(module).new_changeset(params)
    end

    def unquote(String.to_atom("change_#{name}"))() do
      unquote(module).new_changeset(%{})
    end

    def unquote(String.to_atom("create_#{name}"))(params) do
      @repo.insert unquote(module).new_changeset(params)
    end

    def unquote(String.to_atom("create_#{name}!"))(params) do
      @repo.insert! unquote(module).new_changeset(params)
    end

    def unquote(String.to_atom("update_#{name}"))(struct, params) do
      @repo.update unquote(module).changeset(struct, params)
    end

    def unquote(String.to_atom("update_#{name}!"))(struct, params) do
      @repo.update! unquote(module).changeset(struct, params)
    end

    def unquote(String.to_atom("delete_#{name}"))(struct) do
      @repo.delete struct
    end
  end
  <%= if trackable? do %>
  def last_trackable(user_id) do
    schema =
      @repo.one <%= base %>.Coherence.Trackable
        |> where([t], t.user_id == ^user_id)
        |> order_by(desc: :id)
        |> limit(1)
    case schema do
      nil -> <%= base %>.Coherence.Trackable.__struct__
      trackable -> trackable
    end
  end
  <% end %>
  def query_by(schema, opts) do
    Enum.reduce opts, schema, fn {k, v}, query ->
      where(query, [b], field(b, ^k) == ^v)
    end
  end

  def delete_all(%Ecto.Query{} = query) do
    @repo.delete_all query
  end

  def delete_all(module) when is_atom(module) do
    @repo.delete_all module
  end

  def create(%Ecto.Changeset{} = changeset) do
    @repo.insert changeset
  end

  def create!(%Ecto.Changeset{} = changeset) do
    @repo.insert! changeset
  end

  def update(%Ecto.Changeset{} = changeset) do
    @repo.update changeset
  end

  def update!(%Ecto.Changeset{} = changeset) do
    @repo.update! changeset
  end

  def delete(schema) do
    @repo.delete schema
  end

  def delete!(schema) do
    @repo.delete! schema
  end

end
