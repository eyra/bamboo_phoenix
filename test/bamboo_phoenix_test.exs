defmodule Bamboo.PhoenixTest do
  use ExUnit.Case

  defmodule PhoenixLayoutHTML do
    # Layout templates that wrap content
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
    use Bamboo.Phoenix, view: EmailHTML

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
end