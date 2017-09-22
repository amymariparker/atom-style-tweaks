defmodule AtomStyleTweaks.SlidingSessionTimeout.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  alias AtomStyleTweaksWeb.SlidingSessionTimeout

  setup do
    on_exit fn ->
      Application.put_env(:atom_style_tweaks, SlidingSessionTimeout, nil)
    end

    :ok
  end

  test "init defaults to a 3_600 second timeout" do
    assert SlidingSessionTimeout.init() == [timeout: 3_600]
  end

  test "init allows timeout to be overridden" do
    assert SlidingSessionTimeout.init(timeout: 4_000) == [timeout: 4_000]
  end

  test "init allows other options to be specified and merged" do
    assert SlidingSessionTimeout.init(foo: "bar") == [timeout: 3_600, foo: "bar"]
  end

  test "reads a timeout from the config if it exists" do
    Application.put_env(:atom_style_tweaks, SlidingSessionTimeout, [timeout: 5_000])

    assert SlidingSessionTimeout.init() == [timeout: 5_000]
  end

  test "a timeout is set if one doesn't exist" do
    opts = SlidingSessionTimeout.init()

    request = conn(:get, "/")
    timeout_at = request
                 |> init_test_session(%{})
                 |> SlidingSessionTimeout.call(opts)
                 |> fetch_session
                 |> get_session(:timeout_at)

    assert_in_delta timeout_at, now() + 3_600, 2
  end

  test "timeout is set to now plus the timeout value in the session if it doesn't exist" do
    opts = SlidingSessionTimeout.init([timeout: 50_000])

    request = conn(:get, "/")
    timeout_at = request
                 |> init_test_session(%{})
                 |> SlidingSessionTimeout.call(opts)
                 |> fetch_session
                 |> get_session(:timeout_at)

    assert_in_delta timeout_at, now() + 50_000, 2
  end

  test "timeout is renewed if it isn't timed out" do
    opts = SlidingSessionTimeout.init()

    request = conn(:get, "/")
    timeout_at = request
                 |> init_test_session(%{timeout_at: now() + 1_000})
                 |> SlidingSessionTimeout.call(opts)
                 |> fetch_session
                 |> get_session(:timeout_at)

    assert_in_delta timeout_at, now() + 3_600, 2
  end

  test "session is cleared if it has timed out" do
    opts = SlidingSessionTimeout.init()

    request = conn(:get, "/")
    test_conn = request
                |> init_test_session(%{timeout_at: now() - 1_000, current_user: %{}})
                |> SlidingSessionTimeout.call(opts)
                |> fetch_session

    timeout_at = get_session(test_conn, :timeout_at)
    current_user = get_session(test_conn, :current_user)

    assert is_nil(timeout_at)
    assert is_nil(current_user)
    assert test_conn.assigns.timed_out? === true
  end

  defp now, do: DateTime.to_unix(DateTime.utc_now())
end
