defmodule CoherenceTest.Config do
  use ExUnit.Case
  alias Coherence.Config

  setup do
    defaults = Application.get_env(:coherence, :opts)

    on_exit fn ->
      Application.put_env(:coherence, :opts, defaults)
    end

    :ok
  end

  # test "gets" do
  #   Application.put_env :coherence, :user_schema, nil
  #   refute Config.user_schema
  #   assert Config.user_schema(:test) == :test
  #   Application.put_env :coherence, :user_schema, :test1
  #   assert Config.user_schema() == :test1
  #   assert Config.user_schema(:test) == :test1
  #   Application.put_env :coherence, :user_schema, save
  # end

  # test "gets with default" do
  #   assert Config.create_login == :create_login
  #   assert Config.create_login(:test) == :test
  #   Application.put_env :coherence, :create_login, :test1
  #   assert Config.create_login == :test1
  #   assert Config.create_login(:test) == :test1
  # end

  test "has_option accepts :all" do
    Application.put_env(:coherence, :opts, :all)
    assert Config.has_option(:a)
  end

  test "has_option checks if the option is in the opts" do
    Application.put_env(:coherence, :opts, [:a])
    assert Config.has_option(:a)
  end

  test "has_option with missing option" do
    Application.put_env(:coherence, :opts, [:a])
    refute Config.has_option(:b)
  end

  test "has_action? with :all" do
    Application.put_env(:coherence, :opts, :all)
    assert Config.has_action?(:a, :create)
  end

  test "has_action? with list" do
    Application.put_env(:coherence, :opts, [:a])
    assert Config.has_action?(:a, :create)
  end

  test "has_action? with missing option" do
    Application.put_env(:coherence, :opts, [:a])
    refute Config.has_action?(:b, :create)
  end

  test "has_action? with keywords" do
    Application.put_env(:coherence, :opts, [a: [:create]])
    assert Config.has_action?(:a, :create)
  end

  test "has_action? with keywords and missing action" do
    Application.put_env(:coherence, :opts, [a: [:create]])
    refute Config.has_action?(:a, :new)
  end
end
