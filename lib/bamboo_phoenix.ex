defmodule Bamboo.Phoenix do
  @moduledoc """
  Render emails with Phoenix templates and layouts.

  This module allows rendering emails with Phoenix 1.8+ template modules. Pass an
  atom (e.g. `:welcome_email`) as the template name to render both HTML and
  plain text emails. Use a string if you only want to render one type, e.g.
  `"welcome_email.text"` or `"welcome_email.html"`.

  ## Phoenix 1.8+ Template Modules

  With Phoenix 1.8+, templates are defined as functions in modules instead of
  separate .eex files. Each template function takes a format ("html" or "text")
  as the first argument and assigns as the second.

  Templates can return:
  - Plain strings
  - Phoenix.HTML safe tuples `{:safe, iodata}` from `embed_templates`
  - Phoenix.LiveView.Rendered structs from Phoenix.Component's `~H` sigil

  Layouts can use either string interpolation `\#{@inner_content}` or 
  EEx tags `<%= @inner_content %>` - both work correctly without double-escaping.

  ## Examples

  _Define email templates as functions:_

      defmodule MyAppWeb.EmailHTML do
        def welcome("html", assigns) do
          \"\"\"
          <div>
            <h1>Welcome \#{assigns.user.name}!</h1>
            <p>Thanks for signing up.</p>
          </div>
          \"\"\"
        end

        def welcome("text", assigns) do
          \"\"\"
          Welcome \#{assigns.user.name}!
          
          Thanks for signing up.
          \"\"\"
        end
      end

  _Or using Phoenix.Component with ~H sigil (requires phoenix_live_view):_

      defmodule MyAppWeb.EmailHTML do
        use Phoenix.Component

        def welcome("html", assigns) do
          ~H\"\"\"
          <div>
            <h1>Welcome <%= @user.name %>!</h1>
            <p>Thanks for signing up.</p>
          </div>
          \"\"\"
        end

        def welcome("text", assigns) do
          \"\"\"
          Welcome \#{assigns.user.name}!
          
          Thanks for signing up.
          \"\"\"
        end
      end

  _Set the text and HTML layout for an email:_

      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def welcome_email do
          new_email()
          |> put_text_layout({MyAppWeb.LayoutHTML, :email})
          |> put_html_layout({MyAppWeb.LayoutHTML, :email})
          |> render(:welcome) # Pass atom to render html AND plain text templates
        end
      end

  _Set both the text and HTML layout at the same time:_

      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def welcome_email do
          new_email()
          |> put_layout({MyAppWeb.LayoutHTML, :email})
          |> render(:welcome)
        end
      end

  _Render both text and html emails without layouts:_

      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def welcome_email do
          new_email()
          |> render(:welcome)
        end
      end

  _Make assigns available to a template:_

      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def welcome_email(user) do
          new_email()
          |> assign(:user, user)
          |> render(:welcome)
        end
      end

  _Make assigns available to a template during render call:_

      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def welcome_email(user) do
          new_email()
          |> put_html_layout({MyAppWeb.LayoutHTML, :email})
          |> render(:welcome, user: user)
        end
      end

  _Render an email by passing the template string to render:_

      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def html_email do
          new_email
          |> render("html_email.html")
        end

        def text_email do
          new_email
          |> render("text_email.text")
        end
      end

  ## Complete Example with Layouts

      # my_app_web/email.ex
      defmodule MyApp.Email do
        use Bamboo.Phoenix, template: MyAppWeb.EmailHTML

        def sign_in_email(person) do
          base_email()
          |> to(person)
          |> subject("Your Sign In Link")
          |> assign(:person, person)
          |> render(:sign_in)
        end

        defp base_email do
          new_email
          |> from("Rob Ot <robot@example.com>")
          |> put_header("Reply-To", "support@example.com")
          # This will use the email/2 functions for layouts
          |> put_html_layout({MyAppWeb.LayoutHTML, :email})
        end
      end

      # my_app_web/email_html.ex
      defmodule MyAppWeb.EmailHTML do
        def sign_in("html", assigns) do
          \"\"\"
          <div>
            <h2>Sign In Request</h2>
            <p>Hi \#{assigns.person.name},</p>
            <p>
              <a href="\#{assigns.sign_in_url}">Click here to sign in</a>
            </p>
          </div>
          \"\"\"
        end

        def sign_in("text", assigns) do
          \"\"\"
          Sign In Request
          
          Hi \#{assigns.person.name},
          
          Click here to sign in:
          \#{assigns.sign_in_url}
          \"\"\"
        end
      end

      # my_app_web/layout_html.ex
      defmodule MyAppWeb.LayoutHTML do
        def email("html", assigns) do
          \"\"\"
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="UTF-8">
              <style>
                body { font-family: sans-serif; }
              </style>
            </head>
            <body>
              \#{assigns.inner_content}
              <footer>
                <p>&copy; 2024 My Company</p>
              </footer>
            </body>
          </html>
          \"\"\"
        end

        def email("text", assigns) do
          \"\"\"
          \#{assigns.inner_content}
          
          ---
          © 2024 My Company
          \"\"\"
        end
      end

      # Layouts can also use Phoenix.Component ~H sigil or EEx tags:
      defmodule MyAppWeb.LayoutHTML do
        use Phoenix.Component

        def email("html", assigns) do
          ~H\"\"\"
          <!DOCTYPE html>
          <html>
            <body>
              <%= @inner_content %>
            </body>
          </html>
          \"\"\"
        end
      end
  """

  import Bamboo.Email, only: [put_private: 3]

  defmacro __using__(template: template_module) do
    verify_phoenix_dep()

    quote do
      import Bamboo.Email
      import Bamboo.Phoenix, except: [render: 3]

      @doc """
      Render an Phoenix template and set the body on the email.

      Pass an atom as the template name (:welcome_email) to render HTML *and* plain
      text emails. Use a string if you only want to render one type, e.g.
      "welcome_email.text" or "welcome_email.html". Scroll to the top for more examples.
      """
      def render(email, template, assigns \\ []) do
        Bamboo.Phoenix.render_email(unquote(template_module), email, template, assigns)
      end
    end
  end

  defmacro __using__(opts) do
    raise ArgumentError, """
    expected Bamboo.Phoenix to have a template module set, instead got: #{inspect(opts)}.

    Please set a template module e.g. use Bamboo.Phoenix, template: MyAppWeb.EmailHTML
    """
  end

  defp verify_phoenix_dep do
    unless Code.ensure_loaded?(Phoenix) do
      raise "You tried to use Bamboo.Phoenix, but Phoenix module is not loaded. " <>
              "Please add phoenix to your dependencies."
    end
  end

  @doc """
  Render a Phoenix template and set the body on the email.

  Pass an atom as the template name to render HTML *and* plain text emails,
  e.g. `:welcome`. Use a string if you only want to render one type, e.g.
  `"welcome.text"` or `"welcome.html"`. 
  
  The template name corresponds to a function in your view module that takes
  a format ("html" or "text") as the first argument and assigns as the second.
  """
  def render(_email, _template_name, _assigns) do
    raise "function implemented for documentation only, please call: use Bamboo.Phoenix"
  end

  @doc """
  Sets the layout when rendering HTML templates.

  ## Example

      def html_email_layout do
        new_email
        # Will use MyAppWeb.LayoutHTML's email/2 function for HTML rendering
        |> put_html_layout({MyAppWeb.LayoutHTML, :email})
      end
  """
  def put_html_layout(email, layout) do
    email |> put_private(:html_layout, layout)
  end

  @doc """
  Sets the layout when rendering plain text templates.

  ## Example

      def text_email_layout do
        new_email
        # Will use MyAppWeb.LayoutHTML's email/2 function for text rendering
        |> put_text_layout({MyAppWeb.LayoutHTML, :email})
      end
  """
  def put_text_layout(email, layout) do
    email |> put_private(:text_layout, layout)
  end

  @doc """
  Sets the layout for rendering plain text and HTML templates.

  ## Example

      def text_and_html_email_layout do
        new_email
        # Will use MyAppWeb.LayoutHTML's email/2 function for both HTML and text
        |> put_layout({MyAppWeb.LayoutHTML, :email})
      end
  """
  def put_layout(email, {layout, template}) do
    email
    |> put_text_layout({layout, template})
    |> put_html_layout({layout, template})
  end

  @doc """
  Sets an assign for the email. These will be available when rendering the email
  """
  def assign(%{assigns: assigns} = email, key, value) do
    %{email | assigns: Map.put(assigns, key, value)}
  end

  @doc false
  def render_email(template_module, email, template, assigns) do
    email
    |> put_default_layouts
    |> merge_assigns(assigns)
    |> put_template_module(template_module)
    |> put_template(template)
    |> render
  end

  defp put_default_layouts(%{private: private} = email) do
    private =
      private
      |> Map.put_new(:html_layout, false)
      |> Map.put_new(:text_layout, false)

    %{email | private: private}
  end

  defp merge_assigns(%{assigns: email_assigns} = email, assigns) do
    assigns = email_assigns |> Map.merge(Enum.into(assigns, %{}))
    email |> Map.put(:assigns, assigns)
  end

  defp put_template_module(email, template_module) do
    email |> put_private(:template_module, template_module)
  end

  defp put_template(email, view_template) do
    email |> put_private(:view_template, view_template)
  end

  defp render(%{private: %{view_template: template}} = email) when is_atom(template) do
    render_html_and_text_emails(email)
  end

  defp render(email) do
    render_text_or_html_email(email)
  end

  defp render_html_and_text_emails(email) do
    view_template = Atom.to_string(email.private.view_template)

    email
    |> Map.put(:html_body, render_html(email, view_template <> ".html"))
    |> Map.put(:text_body, render_text(email, view_template <> ".text"))
  end

  defp render_text_or_html_email(email) do
    template = email.private.view_template

    cond do
      String.ends_with?(template, ".html") ->
        email |> Map.put(:html_body, render_html(email, template))

      String.ends_with?(template, ".text") ->
        email |> Map.put(:text_body, render_text(email, template))

      true ->
        raise ArgumentError, """
        Template name must end in either ".html" or ".text". Template name was #{
          inspect(template)
        }

        If you would like to render both and html and text template,
        use an atom without an extension instead.
        """
    end
  end

  defp render_html(email, template) do
    assigns = email.assigns
    template_module = email.private.template_module
    
    # Get the template name without extension
    template_name = template
                   |> String.replace(".html", "")
                   |> String.replace(".text", "")
                   |> String.to_atom()
    
    # Render the template
    content = if function_exported?(template_module, template_name, 2) do
      result = apply(template_module, template_name, ["html", assigns])
      normalize_template_result(result)
    else
      raise ArgumentError, 
        "undefined template #{inspect(template_name)} for module #{inspect(template_module)}"
    end
    
    # Apply layout if present
    case email.private.html_layout do
      false -> 
        content
      {layout_module, layout_template} ->
        # Wrap content in SafeString so it works with both string interpolation
        # and EEx templates without double-escaping
        safe_content = Bamboo.Phoenix.SafeString.new(content)
        layout_assigns = Map.put(assigns, :inner_content, safe_content)
        layout_fn = if is_atom(layout_template), do: layout_template, else: String.to_atom(layout_template)
        result = apply(layout_module, layout_fn, ["html", layout_assigns])
        normalize_template_result(result)
    end
  end

  defp render_text(email, template) do
    assigns = email.assigns
    template_module = email.private.template_module
    
    # Get the template name without extension
    template_name = template
                   |> String.replace(".html", "")
                   |> String.replace(".text", "")
                   |> String.to_atom()
    
    # Render the template  
    content = if function_exported?(template_module, template_name, 2) do
      result = apply(template_module, template_name, ["text", assigns])
      normalize_template_result(result)
    else
      raise ArgumentError, 
        "undefined template #{inspect(template_name)} for module #{inspect(template_module)}"
    end
    
    # Apply layout if present
    case email.private.text_layout do
      false -> 
        content
      {layout_module, layout_template} ->
        # For text templates, content doesn't need to be marked as safe
        layout_assigns = Map.put(assigns, :inner_content, content)
        layout_fn = if is_atom(layout_template), do: layout_template, else: String.to_atom(layout_template)
        result = apply(layout_module, layout_fn, ["text", layout_assigns])
        normalize_template_result(result)
    end
  end

  # Convert Phoenix.HTML safe tuples to strings, handling nested safe tuples
  defp normalize_template_result({:safe, iodata}) do
    iodata
    |> flatten_safe_iodata()
    |> IO.iodata_to_binary()
  end

  defp normalize_template_result(binary) when is_binary(binary) do
    binary
  end

  defp normalize_template_result(other) do
    # Only handle known safe types, not arbitrary tuples that might implement Phoenix.HTML.Safe
    cond do
      # Handle structs that implement Phoenix.HTML.Safe (like Phoenix.LiveView.Rendered)
      is_struct(other) && Phoenix.HTML.Safe.impl_for(other) ->
        other
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()
      
      true ->
        raise ArgumentError, """
        Expected template to return a string, {:safe, iodata} tuple, or struct implementing Phoenix.HTML.Safe, got: #{inspect(other)}
        
        Templates should return either:
        - A plain string: "<div>content</div>"
        - A Phoenix.HTML safe tuple: {:safe, ["<div>", "content", "</div>"]}
        - A struct implementing Phoenix.HTML.Safe (like Phoenix.LiveView.Rendered from ~H sigil)
        """
    end
  end

  # Flatten nested safe tuples in iodata
  defp flatten_safe_iodata(data) when is_list(data) do
    Enum.map(data, &flatten_safe_iodata/1)
  end

  defp flatten_safe_iodata({:safe, inner}) do
    flatten_safe_iodata(inner)
  end

  # Handle SafeString structs in iodata - convert to their content
  defp flatten_safe_iodata(%Bamboo.Phoenix.SafeString{content: content}) do
    content
  end

  defp flatten_safe_iodata(binary) when is_binary(binary) do
    binary
  end

  defp flatten_safe_iodata(other) do
    other
  end
end
