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
