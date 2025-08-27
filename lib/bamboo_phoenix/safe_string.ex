defmodule Bamboo.Phoenix.SafeString do
  @moduledoc """
  A struct that wraps HTML content to work with both string interpolation
  and EEx templates in layouts without causing double-escaping.

  This struct implements both `String.Chars` (for `\#{@inner_content}` in templates)
  and `Phoenix.HTML.Safe` (for `<%= @inner_content %>` in templates).
  """
  defstruct [:content]

  @doc false
  def new(content) when is_binary(content) do
    %__MODULE__{content: content}
  end
end

# For string interpolation in templates (e.g., #{@inner_content})
defimpl String.Chars, for: Bamboo.Phoenix.SafeString do
  def to_string(%{content: content}), do: content
end

# For EEx templates (e.g., <%= @inner_content %>)  
defimpl Phoenix.HTML.Safe, for: Bamboo.Phoenix.SafeString do
  def to_iodata(%{content: content}), do: content
end