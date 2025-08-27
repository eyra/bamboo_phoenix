defmodule Bamboo.PhoenixTest do
  use ExUnit.Case

  defmodule PhoenixLayoutHTML do
    # Simple layout templates - no need to handle safe tuples explicitly
    def app("html", assigns) do
      """
      <!DOCTYPE html>
      <html>
        <head>
          <title>Email Layout</title>
        </head>
        <body style="font-family: sans-serif;">
          <header>
            <h1>My App</h1>
          </header>
          <main>
            #{assigns.inner_content}
          </main>
          <footer>
            <p>&copy; 2024 My Company</p>
          </footer>
        </body>
      </html>
      """
    end

    def app("text", assigns) do
      """
      MY APP
      ======

      #{assigns.inner_content}

      ---
      © 2024 My Company
      """
    end
  end

  defmodule EmailHTML do
    # Email template functions with real HTML/text content
    def text_and_html_email("html", _assigns) do
      """
      <div>
        <h2>Welcome!</h2>
        <p>This is a <strong>test email</strong> with HTML content.</p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
      </div>
      """
    end

    def text_and_html_email("text", _assigns) do
      """
      Welcome!

      This is a test email with plain text content.

      * Item 1
      * Item 2
      """
    end

    def email_with_assigns("html", assigns) do
      """
      <div>
        <h2>Hello <strong>#{assigns.user.name}</strong>!</h2>
        <p>Your account has been created successfully.</p>
        <a href="https://example.com/confirm">Confirm your email</a>
      </div>
      """
    end

    def email_with_assigns("text", assigns) do
      """
      Hello #{assigns.user.name}!

      Your account has been created successfully.

      Confirm your email: https://example.com/confirm
      """
    end

    def html_email("html", _assigns) do
      """
      <div style="background-color: #f0f0f0; padding: 20px;">
        <h1 style="color: #333;">HTML Only Email</h1>
        <p>This email only has an <em>HTML version</em>.</p>
        <button style="background-color: #007bff; color: white; padding: 10px 20px;">
          Click Me
        </button>
      </div>
      """
    end

    def text_email("text", _assigns) do
      """
      TEXT ONLY EMAIL
      ===============

      This email only has a plain text version.
      
      No HTML formatting here!
      """
    end

    def function_in_view do
      "function used in Bamboo.TemplateTest but needed because template is compiled"
    end
  end

  defmodule Email do
    use Bamboo.Phoenix, template: EmailHTML

    def text_and_html_email_with_layout do
      new_email()
      |> put_layout({PhoenixLayoutHTML, :app})
      |> render(:text_and_html_email)
    end

    def text_and_html_email do
      new_email()
      |> render(:text_and_html_email)
    end

    def email_with_assigns(user) do
      new_email()
      |> render(:email_with_assigns, user: user)
    end

    def email_with_already_assigned_user(user) do
      new_email()
      |> assign(:user, user)
      |> render(:email_with_assigns)
    end

    def html_email do
      new_email()
      |> render("html_email.html")
    end

    def text_email do
      new_email()
      |> render("text_email.text")
    end

    def no_template do
      new_email()
      |> render(:non_existent)
    end

    def invalid_template do
      new_email()
      |> render("template.foobar")
    end
  end

  test "render/2 allows setting a custom layout" do
    email = Email.text_and_html_email_with_layout()

    # Check HTML layout wrapping
    assert email.html_body =~ "<!DOCTYPE html>"
    assert email.html_body =~ "<h1>My App</h1>"
    assert email.html_body =~ "<h2>Welcome!</h2>"
    assert email.html_body =~ "&copy; 2024 My Company"
    
    # Check text layout wrapping
    assert email.text_body =~ "MY APP"
    assert email.text_body =~ "Welcome!"
    assert email.text_body =~ "© 2024 My Company"
  end

  test "render/2 renders html and text emails" do
    email = Email.text_and_html_email()

    assert email.html_body =~ "<h2>Welcome!</h2>"
    assert email.html_body =~ "<strong>test email</strong>"
    assert email.text_body =~ "Welcome!"
    assert email.text_body =~ "* Item 1"
  end

  test "render/2 renders html and text emails with assigns" do
    name = "Paul"
    email = Email.email_with_assigns(%{name: name})
    assert email.html_body =~ "<strong>#{name}</strong>"
    assert email.html_body =~ "Confirm your email</a>"
    assert email.text_body =~ "Hello #{name}!"
    assert email.text_body =~ "https://example.com/confirm"

    name = "Jane"
    email = Email.email_with_already_assigned_user(%{name: name})
    assert email.html_body =~ "<strong>#{name}</strong>"
    assert email.text_body =~ "Hello #{name}!"
  end

  test "render/2 renders html body if template extension is .html" do
    email = Email.html_email()

    assert email.html_body =~ "<h1 style=\"color: #333;\">HTML Only Email</h1>"
    assert email.html_body =~ "<button"
    assert email.text_body == nil
  end

  test "render/2 renders text body if template extension is .text" do
    email = Email.text_email()

    assert email.html_body == nil
    assert email.text_body =~ "TEXT ONLY EMAIL"
    assert email.text_body =~ "No HTML formatting"
  end

  test "render/2 raises if template doesn't exist" do
    assert_raise ArgumentError, fn ->
      Email.no_template()
    end
  end

  test "render/2 raises if you pass an invalid template extension" do
    assert_raise ArgumentError, ~r/must end in either ".html" or ".text"/, fn ->
      Email.invalid_template()
    end
  end

  test "render raises if called directly" do
    assert_raise RuntimeError, ~r/documentation only/, fn ->
      Bamboo.Phoenix.render(:foo, :foo, :foo)
    end
  end

  describe "safe tuple handling" do
    defmodule SafeTupleLayoutHTML do
      # Simulates Phoenix.HTML safe tuples from embed_templates
      def app("html", assigns) do
        {:safe, ["<html><body>", assigns.inner_content, "</body></html>"]}
      end

      def app("text", assigns) do
        # Text templates usually return strings, but test both
        "Header\n#{assigns.inner_content}\nFooter"
      end
    end

    defmodule SafeTupleEmailHTML do
      # Simulates templates that return safe tuples
      def welcome("html", assigns) do
        {:safe, ["<h1>Hello ", assigns.name, "</h1>"]}
      end

      def welcome("text", assigns) do
        "Hello #{assigns.name}"
      end

      # Mixed return types
      def mixed("html", _assigns) do
        {:safe, ["<div>Safe tuple content</div>"]}
      end

      def mixed("text", _assigns) do
        "Plain string content"
      end
    end

    defmodule SafeTupleEmail do
      use Bamboo.Phoenix, template: SafeTupleEmailHTML

      def welcome_with_safe_layout(name) do
        new_email()
        |> put_layout({SafeTupleLayoutHTML, :app})
        |> assign(:name, name)
        |> render(:welcome)
      end

      def mixed_return_types do
        new_email()
        |> render(:mixed)
      end
    end

    test "handles safe tuples from templates" do
      email = SafeTupleEmail.mixed_return_types()
      assert email.html_body == "<div>Safe tuple content</div>"
      assert email.text_body == "Plain string content"
    end

    test "handles safe tuples with layouts" do
      email = SafeTupleEmail.welcome_with_safe_layout("Alice")
      assert email.html_body == "<html><body><h1>Hello Alice</h1></body></html>"
      assert email.text_body == "Header\nHello Alice\nFooter"
    end
  end

  describe "additional edge cases" do
    defmodule EdgeCaseHTML do
      # Test empty templates
      def empty("html", _assigns), do: ""
      def empty("text", _assigns), do: ""

      # Test templates with only whitespace
      def whitespace("html", _assigns), do: "   \n\t  "
      def whitespace("text", _assigns), do: "   \n\t  "

      # Test templates with special characters
      def special_chars("html", assigns) do
        "<div>Special: #{assigns.content}</div>"
      end
      def special_chars("text", assigns) do
        "Special: #{assigns.content}"
      end

      # Test invalid return type (for error testing)
      def invalid_return("html", _assigns), do: {:invalid, "data"}
      def invalid_return("text", _assigns), do: nil
    end

    defmodule EdgeCaseEmail do
      use Bamboo.Phoenix, template: EdgeCaseHTML

      def empty_email, do: new_email() |> render(:empty)
      def whitespace_email, do: new_email() |> render(:whitespace)
      def special_chars_email(content) do
        new_email() |> assign(:content, content) |> render(:special_chars)
      end
      def invalid_html_email, do: new_email() |> render("invalid_return.html")
      def invalid_text_email, do: new_email() |> render("invalid_return.text")
    end

    test "handles empty templates" do
      email = EdgeCaseEmail.empty_email()
      assert email.html_body == ""
      assert email.text_body == ""
    end

    test "handles whitespace-only templates" do
      email = EdgeCaseEmail.whitespace_email()
      assert email.html_body == "   \n\t  "
      assert email.text_body == "   \n\t  "
    end

    test "handles special characters in content" do
      email = EdgeCaseEmail.special_chars_email("<script>alert('xss')</script>")
      assert email.html_body == "<div>Special: <script>alert('xss')</script></div>"
      assert email.text_body == "Special: <script>alert('xss')</script>"
    end

    test "raises on invalid return type from HTML template" do
      assert_raise ArgumentError, ~r/Expected template to return a string/, fn ->
        EdgeCaseEmail.invalid_html_email()
      end
    end

    test "raises on invalid return type from text template" do
      assert_raise ArgumentError, ~r/Expected template to return a string/, fn ->
        EdgeCaseEmail.invalid_text_email()
      end
    end
  end

  describe "layout edge cases" do
    defmodule ComplexLayoutHTML do
      # Layout that returns safe tuple
      def safe_layout("html", assigns) do
        {:safe, ["<html>", assigns.inner_content, "</html>"]}
      end

      def safe_layout("text", assigns) do
        {:safe, [assigns.inner_content, "\n--footer--"]}
      end

      # Nested iodata in safe tuple
      def nested_safe("html", assigns) do
        {:safe, ["<div>", ["<span>", assigns.inner_content, "</span>"], "</div>"]}
      end

      def nested_safe("text", assigns) do
        "Text: #{assigns.inner_content}"
      end
    end

    defmodule ComplexLayoutEmail do
      use Bamboo.Phoenix, template: EmailHTML

      def with_safe_layout do
        new_email()
        |> put_layout({ComplexLayoutHTML, :safe_layout})
        |> render(:text_and_html_email)
      end

      def with_nested_safe_layout do
        new_email()
        |> put_layout({ComplexLayoutHTML, :nested_safe})
        |> render(:text_and_html_email)
      end
    end

    test "handles safe tuple layouts" do
      email = ComplexLayoutEmail.with_safe_layout()
      assert email.html_body =~ "<html>"
      assert email.html_body =~ "</html>"
      assert email.text_body =~ "--footer--"
    end

    test "handles nested iodata in safe tuples" do
      email = ComplexLayoutEmail.with_nested_safe_layout()
      assert email.html_body =~ "<div><span>"
      assert email.html_body =~ "</span></div>"
      assert email.text_body =~ "Text:"
    end
  end

  describe "layout configuration" do
    defmodule LayoutConfigEmail do
      use Bamboo.Phoenix, template: EmailHTML

      def with_html_layout_only do
        new_email()
        |> put_html_layout({PhoenixLayoutHTML, :app})
        |> render(:text_and_html_email)
      end

      def with_text_layout_only do
        new_email()
        |> put_text_layout({PhoenixLayoutHTML, :app})
        |> render(:text_and_html_email)
      end

      def with_both_layouts do
        new_email()
        |> put_layout({PhoenixLayoutHTML, :app})
        |> render(:text_and_html_email)
      end
    end

    test "put_html_layout/2 sets only HTML layout" do
      email = LayoutConfigEmail.with_html_layout_only()
      
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.text_body =~ "Welcome!"
      refute email.text_body =~ "MY APP"  # No text layout applied
    end

    test "put_text_layout/2 sets only text layout" do
      email = LayoutConfigEmail.with_text_layout_only()
      
      assert email.text_body =~ "MY APP"
      assert email.html_body =~ "<h2>Welcome!</h2>"
      refute email.html_body =~ "<!DOCTYPE html>"  # No HTML layout applied
    end

    test "put_layout/2 sets both layouts" do
      email = LayoutConfigEmail.with_both_layouts()
      
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.text_body =~ "MY APP"
    end
  end

  describe "error messages" do
    test "provides helpful error for missing template module" do
      assert_raise ArgumentError, ~r/expected Bamboo.Phoenix to have a template module set/, fn ->
        defmodule InvalidEmail do
          use Bamboo.Phoenix, foo: :bar
        end
      end
    end

    test "provides helpful error for undefined template" do
      assert_raise ArgumentError, ~r/undefined template :non_existent for module/, fn ->
        Email.no_template()
      end
    end
  end

  describe "Phoenix.Component ~H sigil support (simulated)" do
    defmodule SimulatedHeexEmailHTML do
      # Simulate what ~H sigil returns - safe tuples with iodata
      def heex_template("html", assigns) do
        {:safe, [
          "<div class=\"email-container\">\n  <h1>Hello ",
          assigns.user.name,
          "!</h1>\n  <p>Welcome to our <strong>platform</strong>.</p>\n  ",
          if(assigns.show_button, do: "<button class=\"btn-primary\">Click Me</button>\n  ", else: ""),
          "\n</div>\n"
        ]}
      end
      
      def heex_template("text", assigns) do
        """
        Hello #{assigns.user.name}!
        
        Welcome to our platform.
        #{if assigns.show_button, do: "Click the button to continue.", else: ""}
        """
      end
      
      def mixed_heex("html", assigns) do
        # Simulates nested safe tuples that ~H can produce
        {:safe, [
          "<div>\n  <h2>Mixed Template</h2>\n  ",
          {:safe, ["<div>Special content for ", assigns.user.role, "</div>"]},
          "\n  <p>Footer text</p>\n</div>"
        ]}
      end
      
      def mixed_heex("text", _assigns) do
        "Mixed template text version"
      end
    end
    
    defmodule SimulatedHeexLayoutHTML do
      # Simulate ~H layout that receives inner_content
      def heex_layout("html", assigns) do
        # ~H would handle inner_content automatically, converting safe tuples
        {:safe, [
          "<!DOCTYPE html>\n<html>\n  <head>\n    <title>Email</title>\n  </head>\n  <body>\n    <header>My App Header</header>\n    ",
          assigns.inner_content,
          "\n    <footer>&copy; 2024</footer>\n  </body>\n</html>"
        ]}
      end
      
      def heex_layout("text", assigns) do
        """
        === MY APP ===
        
        #{assigns.inner_content}
        
        ---
        (c) 2024
        """
      end
    end
    
    defmodule HeexEmail do
      use Bamboo.Phoenix, template: SimulatedHeexEmailHTML
      
      def heex_email(user, show_button \\ true) do
        new_email()
        |> assign(:user, user)
        |> assign(:show_button, show_button)
        |> render(:heex_template)
      end
      
      def heex_email_with_layout(user) do
        new_email()
        |> put_layout({SimulatedHeexLayoutHTML, :heex_layout})
        |> assign(:user, user)
        |> assign(:show_button, true)
        |> render(:heex_template)
      end
      
      def mixed_heex_email(user) do
        new_email()
        |> assign(:user, %{name: user.name, role: "admin"})
        |> render(:mixed_heex)
      end
    end
    
    test "~H sigil-style templates work correctly" do
      user = %{name: "Alice"}
      email = HeexEmail.heex_email(user)
      
      assert email.html_body =~ "<h1>Hello Alice!</h1>"
      assert email.html_body =~ "<strong>platform</strong>"
      assert email.html_body =~ "<button class=\"btn-primary\">Click Me</button>"
      assert email.text_body =~ "Hello Alice!"
      assert email.text_body =~ "Click the button to continue."
    end
    
    test "~H sigil-style templates work with conditional rendering" do
      user = %{name: "Bob"}
      email = HeexEmail.heex_email(user, false)
      
      assert email.html_body =~ "<h1>Hello Bob!</h1>"
      refute email.html_body =~ "<button"
      assert email.text_body =~ "Hello Bob!"
      refute email.text_body =~ "Click the button"
    end
    
    test "~H sigil-style templates work with layouts" do
      user = %{name: "Charlie"}
      email = HeexEmail.heex_email_with_layout(user)
      
      # Check layout wrapping
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "<header>My App Header</header>"
      assert email.html_body =~ "<h1>Hello Charlie!</h1>"
      assert email.html_body =~ "<footer>&copy; 2024</footer>"
      
      assert email.text_body =~ "=== MY APP ==="
      assert email.text_body =~ "Hello Charlie!"
      assert email.text_body =~ "(c) 2024"
    end
    
    test "~H sigil-style with nested safe tuples" do
      user = %{name: "Diana", role: "admin"}
      email = HeexEmail.mixed_heex_email(user)
      
      assert email.html_body =~ "<h2>Mixed Template</h2>"
      assert email.html_body =~ "Special content for admin"
      assert email.html_body =~ "<p>Footer text</p>"
    end
  end

  describe "embedded templates with layouts (no double-escaping)" do
    defmodule EmbeddedLayoutHTML do
      # Simulates a layout using embedded templates that would escape content
      def escaping_layout("html", assigns) do
        # This simulates what happens with <%= @inner_content %> in embedded templates
        # If inner_content isn't marked as safe, it would be escaped
        {:safe, 
          [
            "<html><body>",
            assigns.inner_content,  # This would escape if not marked as safe
            "</body></html>"
          ]
        }
      end

      def escaping_layout("text", assigns) do
        "Layout: #{assigns.inner_content}"
      end
    end

    defmodule HTMLContentEmail do
      # Templates with HTML that could be double-escaped
      def with_html_tags("html", _assigns) do
        "<h1>Title</h1><p>Content with <strong>HTML</strong></p>"
      end

      def with_html_tags("text", _assigns) do
        "Title\nContent with HTML"
      end

      def with_special_chars("html", assigns) do
        "<div>Price: $#{assigns.price} & tax</div>"
      end

      def with_special_chars("text", assigns) do
        "Price: $#{assigns.price} & tax"
      end
    end

    defmodule EscapingTestEmail do
      use Bamboo.Phoenix, template: HTMLContentEmail

      def html_content_with_layout do
        new_email()
        |> put_layout({EmbeddedLayoutHTML, :escaping_layout})
        |> render(:with_html_tags)
      end

      def special_chars_with_layout(price) do
        new_email()
        |> put_layout({EmbeddedLayoutHTML, :escaping_layout})
        |> assign(:price, price)
        |> render(:with_special_chars)
      end
    end

    test "does not double-escape HTML content in layouts" do
      email = EscapingTestEmail.html_content_with_layout()
      
      # Should contain actual HTML tags, not escaped versions
      assert email.html_body =~ "<h1>Title</h1>"
      assert email.html_body =~ "<strong>HTML</strong>"
      
      # Should NOT contain escaped HTML
      refute email.html_body =~ "&lt;h1&gt;"
      refute email.html_body =~ "&lt;strong&gt;"
    end

    test "preserves special characters without double-escaping" do
      email = EscapingTestEmail.special_chars_with_layout("99.99")
      
      # Should contain the actual characters
      assert email.html_body =~ "$99.99 & tax"
      
      # Should NOT double-escape ampersand
      refute email.html_body =~ "&amp;amp;"
    end

    test "text templates are not affected by safe marking" do
      email = EscapingTestEmail.html_content_with_layout()
      assert email.text_body == "Layout: Title\nContent with HTML"
    end
  end
end