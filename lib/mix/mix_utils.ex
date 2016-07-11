defmodule Coherence.Mix.Utils do

  def rm_dir!(dir) do
    if File.dir? dir do
      File.rm_rf dir
    end
  end

  def rm!(file) do
    if File.exists? file do
      File.rm! file
    end
  end

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
