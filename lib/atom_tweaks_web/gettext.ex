defmodule AtomTweaksWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import AtomTweaks.Gettext

      # Simple translation
      gettext "Here is the string to translate"

      # Plural translation
      ngettext "Here is the string to translate",
               "Here are the strings to translate",
               3

      # Domain-based translation
      dgettext "errors", "Here is the error message to translate"

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """

  use Gettext, otp_app: :atom_tweaks

  alias Phoenix.HTML

  alias AtomTweaksWeb.MarkdownEngine

  @doc """
  Render the output of a `gettext` macro into HTML from Markdown.
  """
  def md(text) do
    text
    |> MarkdownEngine.render()
    |> HTML.raw()
  end
end
