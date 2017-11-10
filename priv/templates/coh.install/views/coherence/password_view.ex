defmodule <%= web_base %>.Coherence.PasswordView do
  use <%= web_module %>, :view

  def render("password.json", %{info: info}) do
    %{info: info}
  end
  def render("password.json", %{error: error}) do
    %{error: error}
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end
  def render("error.json", %{changeset: changeset}) do
    changeset =
      cond do
        is_nil(changeset) || changeset == "" -> "Unknown error."
        is_bitstring(changeset) -> changeset
        true -> error_string_from_changeset(changeset)
      end

    %{error: changeset}
  end
end
