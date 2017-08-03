defmodule Coherence.Schemas do

  use Coherence.Config

  import Ecto.Query

  def schema(schema) do
    Module.concat [Config.module, Coherence, schema]
  end

  def list_user do
    Config.repo.all Config.user_schema
  end

  def list_by_user(opts) do
    Config.repo.all query_by(Config.user_schema, opts)
  end

  def get_by_user(opts) do
    Config.repo.get_by Config.user_schema, opts
  end

  def get_user(id) do
    Config.repo.get Config.user_schema, id
  end

  def get_user!(id) do
    Config.repo.get! Config.user_schema, id
  end

  def get_user_by_email(email) do
    Config.repo.get_by Config.user_schema, email: email
  end

  def change_user(struct, params) do
    Config.user_schema.changeset struct, params
  end

  def change_user(params) do
    Config.user_schema.changeset Config.user_schema.__struct__, params
  end

  def change_user do
    Config.user_schema.changeset Config.user_schema.__struct__, %{}
  end

  def create_user(params) do
    user_schema = Config.user_schema
    Config.repo.insert user_schema.new_changeset(params)
  end

  def create_user!(params) do
    user_schema = Config.user_schema
    Config.repo.insert! user_schema.new_changeset(params)
  end

  def update_user(user, params) do
    Config.repo.update user.__struct__.changeset(user, params)
  end

  def update_user!(user, params) do
    Config.repo.update! user.__struct__.changeset(user, params)
  end

  Enum.each [Invitation, Rememberable, Trackable], fn module ->
    name = module |> inspect |> String.downcase

    def unquote(String.to_atom("list_#{name}"))() do
      Config.repo.all schema(unquote(module))
    end

    def unquote(String.to_atom("list_by_#{name}"))(opts) do
      Config.repo.all query_by(schema(unquote(module)), opts)
    end

    def unquote(String.to_atom("list_#{name}"))(%Ecto.Query{} = query) do
      Config.repo.all query
    end

    def unquote(String.to_atom("get_#{name}"))(id) do
      Config.repo.get schema(unquote(module)), id
    end

    def unquote(String.to_atom("get_#{name}!"))(id) do
      Config.repo.get! schema(unquote(module)), id
    end

    def unquote(String.to_atom("get_by_#{name}"))(opts) do
      Config.repo.get_by schema(unquote(module)), opts
    end

    def unquote(String.to_atom("change_#{name}"))(struct, params) do
      schema(unquote(module)).changeset(struct, params)
    end

    def unquote(String.to_atom("change_#{name}"))(params) do
      schema(unquote(module)).new_changeset(params)
    end

    def unquote(String.to_atom("change_#{name}"))() do
      schema(unquote(module)).new_changeset(%{})
    end

    def unquote(String.to_atom("create_#{name}"))(params) do
      Config.repo.insert schema(unquote(module)).new_changeset(params)
    end

    def unquote(String.to_atom("create_#{name}!"))(params) do
      Config.repo.insert! schema(unquote(module)).new_changeset(params)
    end

    def unquote(String.to_atom("update_#{name}"))(struct, params) do
      Config.repo.update schema(unquote(module)).changeset(struct, params)
    end

    def unquote(String.to_atom("update_#{name}!"))(struct, params) do
      Config.repo.update! schema(unquote(module)).changeset(struct, params)
    end

    def unquote(String.to_atom("delete_#{name}"))(struct) do
      Config.repo.delete struct
    end

    def unquote(String.to_atom("delete_#{name}!"))(struct) do
      Config.repo.delete! struct
    end

  end

  def last_trackable(user_id) do
    schema =
      Config.repo.one Trackable
        |> schema
        |> where([t], t.user_id == ^user_id)
        |> order_by(desc: :id)
        |> limit(1)
    case schema do
      nil -> schema(Trackable).__struct__
      trackable -> trackable
    end
  end

  def query_by(schema, opts) do
    Enum.reduce opts, schema(schema), fn {k, v}, query ->
      where(query, [b], field(b, ^k) == ^v)
    end
  end

  def delete_all(%Ecto.Query{} = query) do
    Config.repo.delete_all query
  end

  def delete_all(module) when is_atom(module) do
    Config.repo.delete_all module
  end

  def create(%Ecto.Changeset{} = changeset) do
    Config.repo.insert changeset
  end

  def create!(%Ecto.Changeset{} = changeset) do
    Config.repo.insert! changeset
  end

  def update(%Ecto.Changeset{} = changeset) do
    Config.repo.update changeset
  end

  def update!(%Ecto.Changeset{} = changeset) do
    Config.repo.update! changeset
  end

  def delete(schema) do
    Config.repo.delete schema
  end

  def delete!(schema) do
    Config.repo.delete! schema
  end

end
