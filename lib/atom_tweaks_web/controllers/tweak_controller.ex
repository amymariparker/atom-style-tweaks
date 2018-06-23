defmodule AtomTweaksWeb.TweakController do
  use AtomTweaksWeb, :controller

  alias AtomTweaks.Tweaks
  alias AtomTweaks.Tweaks.Tweak
  alias AtomTweaksWeb.NotLoggedInError
  alias AtomTweaksWeb.PageMetadata
  alias AtomTweaksWeb.WrongUserError

  require Logger

  @doc """
  Creates a new tweak with the given parameters.
  """
  @spec create(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def create(conn, params)

  def create(conn = %{assigns: %{current_user: nil}}, _), do: raise(NotLoggedInError, conn: conn)

  def create(conn, %{"tweak" => tweak_params}) do
    current_user = conn.assigns.current_user
    params = Map.merge(tweak_params, %{"created_by" => current_user.id})
    changeset = Tweak.changeset(%Tweak{}, params)

    case Repo.insert(changeset) do
      {:ok, tweak} -> redirect(conn, to: tweak_path(conn, :show, tweak))
      {:error, changeset} -> render(conn, "new.html", changeset: changeset)
    end
  end

  @doc """
  Deletes the given tweak.

  **Not implemented.**
  """
  @spec delete(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
  end

  @doc """
  Displays the edit tweak form.
  """
  @spec edit(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def edit(conn, params)

  def edit(conn = %{assigns: %{current_user: nil}}, _), do: raise(NotLoggedInError, conn: conn)

  def edit(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    tweak =
      Tweak
      |> Repo.get(id)
      |> Repo.preload([:user])

    if current_user.id != tweak.user.id do
      raise WrongUserError, conn: conn, current_user: current_user, resource_owner: tweak.user
    end

    changeset = Tweak.changeset(tweak)

    render(
      conn,
      "edit.html",
      changeset: changeset,
      tweak: tweak
    )
  end

  @doc """
  Displays the new tweak form.
  """
  @spec new(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def new(conn, params)

  def new(conn = %{assigns: %{current_user: nil}}, _), do: raise(NotLoggedInError, conn: conn)

  def new(conn, _params) do
    changeset = Tweaks.change_tweak(%Tweak{})

    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Displays the given tweak.
  """
  @spec show(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def show(conn, params)

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    tweak =
      Tweak
      |> Repo.get(id)
      |> Repo.preload([:stargazers, :user])

    starred = Tweaks.is_starred?(tweak, current_user)

    conn
    |> PageMetadata.add(Tweak.to_metadata(tweak))
    |> render("show.html", starred: starred, tweak: tweak)
  end

  @doc """
  Updates a tweak with the given parameters.
  """
  @spec update(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def update(conn, params)

  def update(conn, %{"user_id" => name, "id" => id, "tweak" => tweak_params}) do
    tweak = Repo.get(Tweak, id)
    changeset = Tweak.changeset(tweak, tweak_params)

    case Repo.update(changeset) do
      {:ok, tweak} ->
        redirect(conn, to: tweak_path(conn, :show, tweak))

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          name: name,
          tweak: tweak,
          changeset: changeset,
          errors: changeset.errors
        )
    end
  end
end
