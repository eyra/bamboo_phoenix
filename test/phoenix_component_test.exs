defmodule Bamboo.PhoenixComponentTest do
  use ExUnit.Case

  defmodule ComponentEmailHTML do
    use Phoenix.Component

    def reset_password_instructions("html", assigns) do
      ~H"""
      <h1>Reset Your Password</h1>
      <p>Hi <%= @user.displayname %>,</p>
      <p>Click <a href={@url}>here</a> to reset your password.</p>
      """
    end

    def reset_password_instructions("text", assigns) do
      """
      Reset Your Password
      
      Hi #{assigns.user.displayname},
      Click here to reset your password: #{assigns.url}
      """
    end

    def welcome_email("html", assigns) do
      ~H"""
      <div class="email-wrapper">
        <h1>Welcome <%= @user.displayname %>!</h1>
        <p>Your email is: <%= @user.email %></p>
        <div class="special-chars">
          Special characters: <%= @special_content %>
        </div>
      </div>
      """
    end

    def welcome_email("text", assigns) do
      """
      Welcome #{assigns.user.displayname}!
      Your email is: #{assigns.user.email}
      Special characters: #{assigns.special_content}
      """
    end
  end

  defmodule ComponentLayoutHTML do
    use Phoenix.Component

    def email("html", assigns) do
      ~H"""
      <!DOCTYPE html>
      <html>
        <head>
          <title>Email</title>
        </head>
        <body>
          <header>Company Header</header>
          <%= @inner_content %>
          <footer>&copy; 2024 Company</footer>
        </body>
      </html>
      """
    end

    def email("text", assigns) do
      """
      === COMPANY HEADER ===
      
      #{assigns.inner_content}
      
      ---
      © 2024 Company
      """
    end
  end

  defmodule ComponentEmail do
    use Bamboo.Phoenix, template: ComponentEmailHTML

    def reset_password_with_special_chars(user, url) do
      new_email()
      |> from("support@example.com")
      |> to(user.email)
      |> subject("Reset Your Password")
      |> put_layout({ComponentLayoutHTML, :email})
      |> assign(:user, user)
      |> assign(:url, url)
      |> render(:reset_password_instructions)
    end

    def welcome_with_html_entities(user, special_content) do
      new_email()
      |> from("support@example.com")
      |> to(user.email)
      |> subject("Welcome!")
      |> put_layout({ComponentLayoutHTML, :email})
      |> assign(:user, user)
      |> assign(:special_content, special_content)
      |> render(:welcome_email)
    end
  end

  describe "Phoenix.Component with special characters" do
    test "handles user names with ampersands and apostrophes" do
      user = %{displayname: "John & Jane's", email: "test@example.com"}
      url = "https://example.com/reset?token=abc&user=123"
      
      email = ComponentEmail.reset_password_with_special_chars(user, url)
      
      # Check that special characters are properly escaped in HTML
      assert email.html_body =~ "John &amp; Jane&#39;s"
      assert email.html_body =~ "token=abc&amp;user=123"
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "Company Header"
      
      # Check text version has unescaped characters
      assert email.text_body =~ "John & Jane's"
      assert email.text_body =~ "=== COMPANY HEADER ==="
    end

    test "handles HTML tags and entities in content" do
      user = %{
        displayname: "<script>alert('XSS')</script>",
        email: "user@example.com"
      }
      special_content = "This & that < those > these \"quotes\" 'apostrophes'"
      
      email = ComponentEmail.welcome_with_html_entities(user, special_content)
      
      # HTML should escape dangerous content
      assert email.html_body =~ "&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;"
      assert email.html_body =~ "This &amp; that &lt; those &gt; these"
      assert email.html_body =~ "&quot;quotes&quot;"
      assert email.html_body =~ "&#39;apostrophes&#39;"
      
      # Text should have raw content
      assert email.text_body =~ "<script>alert('XSS')</script>"
      assert email.text_body =~ "This & that < those > these \"quotes\" 'apostrophes'"
    end

    test "handles nested safe tuples from component composition" do
      user = %{displayname: "Test & User", email: "test@example.com"}
      url = "https://example.com/path?a=1&b=2"
      
      email = ComponentEmail.reset_password_with_special_chars(user, url)
      
      # Should not have double-escaped entities
      refute email.html_body =~ "&amp;amp;"
      
      # Should have proper single escaping
      assert email.html_body =~ "Test &amp; User"
      assert email.html_body =~ "a=1&amp;b=2"
    end
  end
end