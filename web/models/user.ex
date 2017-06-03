defmodule AtomStyleTweaks.User do
  @moduledoc """
  Represents a user of the application.
  """

  use AtomStyleTweaks.Web, :model

  alias AtomStyleTweaks.User

  @type t :: %User{}

  @derive {Phoenix.Param, key: :name}

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :avatar_url, :string
    field :github_id, :integer
    field :name, :string
    field :site_admin, :boolean, default: false

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:avatar_url, :github_id, :name, :site_admin])
    |> validate_required([:avatar_url, :github_id, :name, :site_admin])
    |> unique_constraint(:name)
    |> unique_constraint(:github_id)
  end
end
