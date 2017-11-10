defmodule <%= web_base %>.Coherence.UnlockView do
  use <%= web_module %>, :view

  def render("unlock.json", %{info: info}) do
    %{
      info: info
    }
  end
  def render("unlock.json", %{user: user}) do
    %{
      user: %{
        id: user.id,
        name: user.name,
        email: user.email
      }
    }
  end

  def render("error.json", %{error: error}) do
    %{
      error: error
    }
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
