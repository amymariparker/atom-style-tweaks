defmodule AtomTweaksWeb.AuthController do
  @moduledoc """
  Handles authentication for the application via GitHub OAuth2 user flow.
  """
  use AtomTweaksWeb, :controller

  alias AtomTweaks.Accounts.User
  alias AtomTweaksWeb.GitHub
  alias OAuth2.Client, as: OAuthClient

  require Logger

  @doc """
  Signs the user in by redirecting to the GitHub authorization URL.
  """
  @spec index(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def index(conn, params)

  def index(conn, %{"from" => return_to}) do
    Logger.debug(fn -> "Authorize user and return to #{return_to}" end)

    conn
    |> put_session(:return_to, return_to)
    |> redirect(external: GitHub.authorize_url!())
  end

  def index(conn, _) do
    Logger.debug(fn -> "Authorize user and return to home page" end)

    redirect(conn, external: GitHub.authorize_url!())
  end

  @doc """
  Signs the user out by dropping the session, thereby throwing away the access
  token, and redirecting to the home page.
  """
  @spec delete(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.page_path(conn, :index))
  end

  @doc """
  Handles the OAuth2 callback from GitHub.
  """
  @spec callback(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def callback(conn, params)

  def callback(conn, %{"code" => code}) do
    token = GitHub.get_token!(code: code)
    github_user = get_user!(token)
    user = create_user(github_user)

    redirect_path = return_to_path(conn, get_session(conn, :return_to))

    conn
    |> delete_session(:return_to)
    |> put_session(:current_user, user)
    |> put_session(:access_token, token.token)
    |> redirect(to: redirect_path)
  end

  defp create_user(github_user) do
    case Repo.get_by(User, name: github_user.name, github_id: github_user.github_id) do
      nil -> Repo.insert!(User.changeset(%User{}, github_user))
      user -> Map.merge(user, github_user)
    end
  end

  defp get_user!(token) do
    {:ok, %{body: user}} = OAuthClient.get(token, "/user")

    %{
      name: user["login"],
      avatar_url: user["avatar_url"],
      github_id: user["id"]
    }
  end

  defp return_to_path(conn, nil), do: Routes.page_path(conn, :index)
  defp return_to_path(_, path), do: path
end
