defmodule AtomStyleTweaks.AuthController do
  @moduledoc """
  Handles authentication for the application via GitHub OAuth2 user flow.
  """
  use AtomStyleTweaks.Web, :controller

  alias AtomStyleTweaks.GitHub

  require Logger

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
    user = get_user!(token)

    conn
    |> put_session(:current_user, user)
    |> put_session(:access_token, token.access_token)
    |> put_flash(:info, "Signed in as #{user.name}")
    |> redirect(to: page_path(conn, :index))
  end

  defp get_user!(token) do
    {:ok, %{body: user}} = OAuth2.AccessToken.get(token, "/user")
    Logger.debug("user = #{inspect user}")

    %{
      name: user["login"],
      avatar: user["avatar_url"],
      member: member?(token),
      site_admin: user["site_admin"]
    }
  end

  defp get_orgs!(token) do
    {:ok, %{body: orgs}} = OAuth2.AccessToken.get(token, "/user/orgs")
    org_names = Enum.map(orgs, fn(org) -> org["login"] end)
    Logger.debug("orgs = #{inspect org_names}")

    org_names
  end

  defp member?(token) do
    auth_org = Application.get_env(:pain_view, :settings)[:org]

    Enum.find(get_orgs!(token), fn(org) -> org == auth_org end)
  end
end
