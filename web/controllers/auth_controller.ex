defmodule AtomStyleTweaks.AuthController do
  @moduledoc """
  Handles authentication for the application via GitHub OAuth2 user flow.
  """
  use AtomStyleTweaks.Web, :controller

  require Logger

  alias AtomStyleTweaks.User

  @doc """
  Signs the user in by redirecting to the GitHub authorization URL.
  """
  def index(conn, _params) do
    conn
    |> redirect(external: GitHub.authorize_url!)
  end

  @doc """
  Signs the user out by dropping the session, thereby throwing away the access
  token, and redirecting to the Pain View home page.
  """
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: page_path(conn, :index))
  end

  @doc """
  Handles the OAuth2 callback from GitHub.
  """
  def callback(conn, %{"code" => code}) do
    token = GitHub.get_token!(code: code)
    github_user = get_user!(token)
    user = create_user(github_user)

    conn
    |> put_session(:current_user, user)
    |> put_session(:access_token, token.token)
    |> put_flash(:info, "Signed in as #{user.name}")
    |> redirect(to: page_path(conn, :index))
  end

  defp create_user(github_user) do
    case Repo.get_by(User, name: github_user.name) do
      nil -> Repo.insert!(User.changeset(%User{}, github_user))
      user -> Map.merge(user, github_user)
    end
  end

  defp get_user!(token) do
    {:ok, %{body: user}} = OAuth2.Client.get(token, "/user")

    %{
      name: user["login"],
      avatar_url: user["avatar_url"]
    }
  end
end
