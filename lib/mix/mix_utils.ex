defmodule Coherence.Mix.Utils do

  @dialyzer [
    {:nowarn_function, raise_option_errors: 1},
  ]

  @spec rm_dir!(String.t) :: any
  def rm_dir!(dir) do
    if File.dir? dir do
      File.rm_rf dir
    end
  end

  @spec rm!(String.t) :: any
  def rm!(file) do
    if File.exists? file do
      File.rm! file
    end
  end

  @spec raise_option_errors([:atom]) :: String.t
  def raise_option_errors(list) do
    list = Enum.map(list, fn option ->
      "--" <> Atom.to_string(option) |> String.replace("_", "-")
    end)
    |> Enum.join(", ")
    Mix.raise """
    The following option(s) are not supported:
        #{inspect list}
    """
  end

  @spec verify_args!([String.t] | [], [String.t] | []) :: String.t | nil
  def verify_args!(parsed, unknown) do
    unless parsed == [] do
      opts = Enum.join parsed, ", "
      Mix.raise """
      Invalid argument(s) #{opts}
      """
    end
    unless unknown == [] do
      opts = Enum.map(unknown, &(elem(&1,0)))
      |> Enum.join(", ")
      Mix.raise """
      Invalid argument(s) #{opts}
      """
    end
  end

end
