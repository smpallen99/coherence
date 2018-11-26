defmodule <%= web_base %>.Coherence.ConfirmationView do
  use <%= web_module %>, :view

  def render("confirmation.json", %{info: info}) do
    %{
      info: info
    }
  end

  def render("error.json", %{changeset: changeset}) do
    changeset = cond do
      is_nil(changeset) || changeset == "" -> "Unknown error."
      is_bitstring(changeset) -> changeset
      true -> error_string_from_changeset(changeset)
    end

    %{error: changeset}
  end
  def render("error.json", %{error: error}) do
    %{error: error}
  end
end
