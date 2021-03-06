defmodule AtomTweaksWeb.Router do
  @moduledoc """
  Routes requests to the website to the appropriate controller.
  """

  use AtomTweaksWeb, :router

  use Plug.ErrorHandler
  use Sentry.Plug

  alias AtomTweaksWeb.HerokuMetadata
  alias AtomTweaksWeb.SlidingSessionTimeout
  alias AtomTweaksWeb.TokenAuthentication

  require Logger

  @doc """
  Plug pipeline for requests sent from a browser.
  """
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:assign_current_user)
    plug(SlidingSessionTimeout)
    plug(NavigationHistory.Tracker)
    plug(HerokuMetadata, only: ["HEROKU_RELEASE_VERSION", "HEROKU_SLUG_COMMIT"])
    plug(Plug.Ribbon, [:dev, :staging, :test])
  end

  @doc """
  Plug pipeline for requests sent to the API.
  """
  pipeline :api do
    plug(:accepts, ["json"])
    plug(TokenAuthentication)
  end

  @doc """
  Plug pipeline of additional checks for routes that require a site admin.
  """
  pipeline :admin_checks do
    plug(:ensure_authenticated_user)
    plug(:ensure_site_admin)
  end

  scope "/", AtomTweaksWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/about", PageController, :about)
    get("/release-notes", PageController, :release_notes)

    get("/auth", AuthController, :index)
    get("/auth/callback", AuthController, :callback)
    get("/auth/logout", AuthController, :delete)

    resources("/tweaks", TweakController, except: [:index]) do
      resources("/forks", ForkController, only: [:create, :index])

      get("/stargazers", StargazerController, :index)
      post("/star", StarController, :toggle)
    end

    resources("/users", UserController, only: [:show]) do
      get("/stars", StarController, :index)
      resources("/tokens", TokenController, only: [:create, :delete, :index, :new])
    end

    # Obsolete routes used to redirect to new URLs
    get("/users/:user_id/tweaks/:tweak_id", ObsoleteRouteController, :long_tweak_path_to_short)
  end

  scope("/admin", AtomTweaksWeb.Admin, as: :admin) do
    pipe_through([:browser, :admin_checks])

    resources("/release-notes", ReleaseNoteController)
  end

  scope "/api", AtomTweaksWeb.Api, as: :api do
    pipe_through(:api)

    resources("/release-notes", ReleaseNoteController, only: [:create])
  end

  @doc """
  Fetch the current user from the session and add it to `conn.assigns`.

  This will allows access to the current user in views with `@current_user`.
  """
  def assign_current_user(conn, opts)

  def assign_current_user(conn, _) do
    user = get_session(conn, :current_user)
    Logger.debug("Current user: #{inspect(user)}")

    assign(conn, :current_user, user)
  end
end
