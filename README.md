# Bamboo.Phoenix [![Circle CI](https://circleci.com/gh/thoughtbot/bamboo_phoenix/tree/main.svg?style=svg)](https://circleci.com/gh/thoughtbot/bamboo_phoenix/tree/main)

**Bamboo & Bamboo.Phoenix are part of the [thoughtbot Elixir family][elixir-phoenix] of projects.**

`Bamboo.Phoenix` is a library to render [Bamboo] emails using Phoenix templates. This package
supports Phoenix 1.8+ which uses function-based templates instead of Phoenix.View.

[Bamboo]: https://github.com/thoughtbot/bamboo
[Bamboo.Phoenix docs]: https://hexdocs.pm/bamboo_phoenix/Bamboo.Phoenix.html

## Requirements

- Phoenix >= 1.8.0
- Bamboo >= 2.5.0
- Elixir >= 1.16

## Installation

Make sure you have `Bamboo` installed. To install `Bamboo.Phoenix`, add it to
your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bamboo_phoenix, "~> 2.0.0"}
  ]
end
```

## Usage

### Basic Setup

Define your email module with template functions:

```elixir
# lib/my_app_web/emails/user_email.ex
defmodule MyApp.UserEmail do
  use Bamboo.Phoenix, template: MyAppWeb.EmailHTML
  
  def welcome_email(user) do
    new_email()
    |> from("noreply@example.com")
    |> to(user.email)
    |> subject("Welcome!")
    |> assign(:user, user)
    |> render(:welcome)
  end
end
```

### Template Modules

With Phoenix 1.8+, templates are defined as functions in modules. These functions can return either:
- Plain strings: `"<div>content</div>"`
- Phoenix.HTML safe tuples: `{:safe, iodata}` (from `embed_templates` or `~H` sigil)

Both return types are handled automatically by bamboo_phoenix.

```elixir
# lib/my_app_web/email_html.ex
defmodule MyAppWeb.EmailHTML do
  # Option 1: Return plain strings
  def welcome("html", assigns) do
    """
    <div style="font-family: sans-serif;">
      <h1>Welcome #{assigns.user.name}!</h1>
      <p>Thanks for joining our platform.</p>
      <a href="#{assigns.confirmation_url}" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
        Confirm your account
      </a>
    </div>
    """
  end
  
  # Option 2: Use embed_templates (returns safe tuples)
  # embed_templates "email_html/*"
  
  # Option 3: Use Phoenix.Component with ~H sigil (returns safe tuples)
  # use Phoenix.Component
  # def welcome("html", assigns) do
  #   ~H"""
  #   <div>
  #     <h1>Welcome <%= @user.name %>!</h1>
  #   </div>
  #   """
  # end
  
  def welcome("text", assigns) do
    """
    Welcome #{assigns.user.name}!
    
    Thanks for joining our platform.
    
    Confirm your account:
    #{assigns.confirmation_url}
    """
  end
  
  # You can have multiple email templates in the same module
  def password_reset("html", assigns) do
    """
    <div>
      <h2>Reset your password</h2>
      <p>Click the link below to reset your password:</p>
      <a href="#{assigns.reset_url}">Reset Password</a>
    </div>
    """
  end
  
  def password_reset("text", assigns) do
    """
    Reset your password
    
    Click the link below to reset your password:
    #{assigns.reset_url}
    """
  end
end
```

### Using Layouts

Layouts wrap your email content with consistent headers/footers:

```elixir
# lib/my_app_web/layout_html.ex
defmodule MyAppWeb.LayoutHTML do
  def email("html", assigns) do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            line-height: 1.6;
            color: #333;
          }
          .container { 
            max-width: 600px; 
            margin: 0 auto; 
            padding: 20px;
          }
          .header { 
            background: #f8f9fa; 
            padding: 20px; 
            text-align: center;
          }
          .footer { 
            margin-top: 40px; 
            padding-top: 20px; 
            border-top: 1px solid #dee2e6;
            text-align: center;
            font-size: 12px;
            color: #6c757d;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>My App</h1>
          </div>
          <div class="content">
            #{assigns.inner_content}
          </div>
          <div class="footer">
            <p>&copy; 2024 My Company. All rights reserved.</p>
            <p>
              <a href="https://example.com/unsubscribe">Unsubscribe</a> |
              <a href="https://example.com/preferences">Email Preferences</a>
            </p>
          </div>
        </div>
      </body>
    </html>
    """
  end
  
  def email("text", assigns) do
    """
    MY APP
    ======
    
    #{assigns.inner_content}
    
    ---
    © 2024 My Company. All rights reserved.
    
    Unsubscribe: https://example.com/unsubscribe
    Email Preferences: https://example.com/preferences
    """
  end
end
```

### Applying Layouts to Emails

```elixir
defmodule MyApp.UserEmail do
  use Bamboo.Phoenix, template: MyAppWeb.EmailHTML
  
  def welcome_email(user) do
    base_email()
    |> to(user.email)
    |> subject("Welcome to My App!")
    |> assign(:user, user)
    |> assign(:confirmation_url, "https://example.com/confirm/#{user.confirmation_token}")
    |> render(:welcome)
  end
  
  defp base_email do
    new_email()
    |> from("support@example.com")
    |> put_layout({MyAppWeb.LayoutHTML, :email})  # Apply layout to all emails
  end
end
```

### Rendering Specific Formats

You can render only HTML or only text emails by using string templates:

```elixir
def html_only_email(user) do
  new_email()
  |> render("welcome.html")  # Only renders HTML version
end

def text_only_email(user) do
  new_email()
  |> render("welcome.text")  # Only renders text version
end
```

## Migration from Phoenix.View

If you're migrating from an older version that used Phoenix.View:

1. **Replace View modules with HTML modules** - Instead of `use Phoenix.View`, create plain modules with template functions
2. **Convert .eex templates to functions** - Each template becomes a function that takes format and assigns
3. **Update layout references** - Change from `LayoutView` to `LayoutHTML` (or your naming convention)
4. **The Bamboo.Phoenix API stays the same** - No changes needed to your email sending code

## Contributing

Before opening a pull request, please open an issue first.

Once we've decided how to move forward with a pull request:

    $ git clone https://github.com/thoughtbot/bamboo_phoenix.git
    $ cd bamboo_phoenix
    $ mix deps.get
    $ mix test
    $ mix format

Once you've made your additions and `mix test` passes, go ahead and open a PR!

We run the test suite as well as formatter checks on CI. Make sure you are using
the Elixir version defined in the `.tool-versions` file to have consistent
formatting with what's being run on CI.

## About thoughtbot

![thoughtbot](http://presskit.thoughtbot.com/images/thoughtbot-logo-for-readmes.svg)

Bamboo & Bamboo.Phoenix area maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open-source software, Elixir, and Phoenix. See [our other Elixir
projects][elixir-phoenix], or [hire our Elixir Phoenix development team][hire]
to design, develop, and grow your product.

[elixir-phoenix]: https://thoughtbot.com/services/elixir-phoenix?utm_source=github
[hire]: https://thoughtbot.com?utm_source=github
