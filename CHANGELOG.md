# Changelog

Most changes for each `bamboo_phoenix` version are included here. For a
complete changelog, see the git history for each version via the version links.

**To see the dates a version was published see the [hex package page].**

## [2.0.0]

### Changed
* **BREAKING:** Migrated from `Phoenix.View` to `Phoenix.Template` for Phoenix 1.8+ compatibility
  * Minimum Phoenix version is now 1.8.0
  * Minimum Bamboo version is now 2.5.0
  * Minimum Elixir version is now 1.16
* **BREAKING:** Changed API from `use Bamboo.Phoenix, view:` to `use Bamboo.Phoenix, template:`
* Template modules now need to define functions instead of using Phoenix.View with .eex files
  * Template functions take format ("html" or "text") as first argument and assigns as second
  * Templates can return either plain strings or `{:safe, iodata}` tuples (from `embed_templates` or `~H` sigil)
  * Layout functions receive `inner_content` in assigns

### Fixed
* Properly handle Phoenix.HTML safe tuples from `embed_templates` and Phoenix.Component `~H` sigil
* Both plain strings and safe tuples are now correctly normalized when rendering with layouts
* Support for Phoenix.LiveView.Rendered structs from ~H sigil
* Fixed double-escaping issues with layouts using `<%= @inner_content %>`
* Layouts can now use either string interpolation `#{@inner_content}` or EEx `<%= @inner_content %>` without issues

### Migration Guide
* Change `use Bamboo.Phoenix, view:` to `use Bamboo.Phoenix, template:`
* Replace `Phoenix.View`-based modules with function-based template modules
* Each template becomes a function: `def template_name(format, assigns)`
* Layouts receive rendered content via `assigns.inner_content`
* Templates can return strings or safe tuples - both work automatically

## [1.0.0]

* Extracts `Bamboo.Phoenix` module from `bamboo` into `bamboo_phoenix` ([66ac36305])

[66ac36305]: https://github.com/thoughtbot/bamboo_phoenix/commit/66ac363051123f925f63ad361b51679afd303265
[1.0.0]: https://github.com/thoughtbot/bamboo_phoenix/releases/tag/v1.0.0
