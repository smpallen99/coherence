defmodule CoherenceTest.Config do
  use ExUnit.Case, async: true
  alias Coherence.Config

  test "gets" do
    refute Config.user_schema
    assert Config.user_schema(:test) == :test
    Application.put_env :coherence, :user_schema, :test1
    assert Config.user_schema() == :test1
    assert Config.user_schema(:test) == :test1
  end

  test "gets with default" do
    assert Config.create_login == :create_login
    assert Config.create_login(:test) == :test
    Application.put_env :coherence, :create_login, :test1
    assert Config.create_login == :test1
    assert Config.create_login(:test) == :test1
  end
end
