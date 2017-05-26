defmodule AtomStyleTweaks.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias AtomStyleTweaks.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import AtomStyleTweaks.Router.Helpers

      # The default endpoint for testing
      @endpoint AtomStyleTweaks.Endpoint

      import AtomStyleTweaks.Factory

      def decoded_response(conn, status_code) do
        html_response(conn, status_code)
        |> HtmlEntities.decode
      end

      def log_in_as(conn, user) do
        Plug.Test.init_test_session(conn, %{current_user: user})
      end

      def request(path_fn, destination, options \\ []) do
        logged_in = Keyword.get(options, :logged_in)
        params = Keyword.get(options, :params)

        conn = Phoenix.ConnTest.build_conn()
               |> maybe_simulate_logged_in_user(logged_in)

        path = apply(AtomStyleTweaks.Router.Helpers, path_fn, [conn, destination])
        Phoenix.ConnTest.dispatch(conn, @endpoint, :get, path, params)
      end

      def maybe_simulate_logged_in_user(conn, true) do
        Plug.Test.init_test_session(conn, %{current_user: build(:user)})
      end

      def maybe_simulate_logged_in_user(conn, _), do: conn
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AtomStyleTweaks.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(AtomStyleTweaks.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
