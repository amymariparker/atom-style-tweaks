defmodule AtomTweaksWeb.Admin.ReleaseNoteController do
  @moduledoc """
  Handles all admin release notes resources.
  """

  use AtomTweaksWeb, :controller

  alias AtomTweaks.Releases

  @doc """
  Renders the list of release notes.
  """
  def index(conn, _params) do
    notes = Releases.list_notes()

    render(conn, "index.html", notes: notes)
  end

  def show(conn, %{"id" => id}) do
    note = Releases.get_note!(id)

    render(conn, "show.html", note: note)
  end
end
