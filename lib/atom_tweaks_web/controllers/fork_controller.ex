defmodule AtomTweaksWeb.ForkController do
  @moduledoc """
  Handles requests for forked tweak records.
  """

  use AtomTweaksWeb, :controller

  alias AtomTweaks.Accounts
  alias AtomTweaks.Tweaks

  @doc """
  Forks a tweak for the currently logged in user.

  Redirects to the newly created tweak upon success.
  """
  def create(conn = %{assigns: %{current_user: user}}, %{"tweak_id" => id}) when user != nil do
    tweak = Tweaks.get_tweak!(id)
    user = Accounts.get_user!(user.name)

    {:ok, new_tweak} = Tweaks.fork_tweak(tweak, user)

    redirect(conn, to: tweak_path(conn, :show, new_tweak))
  end

  @doc """
  Displays the list of forks of a given tweak.
  """
  def index(conn, %{"tweak_id" => _id}) do
    conn
  end
end
