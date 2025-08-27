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
* View modules now need to define template functions instead of using Phoenix.View with .eex files
  * Template functions take format ("html" or "text") as first argument and assigns as second
  * Layout functions receive `inner_content` in assigns instead of using `@view_module` and `@view_template`

### Migration Guide
* Replace `Phoenix.View`-based modules with function-based template modules
* Each template becomes a function: `def template_name(format, assigns)`
* Layouts receive rendered content via `assigns.inner_content`
* The Bamboo.Phoenix API (`render/2`, `put_layout/2`, etc.) remains unchanged

## [1.0.0]

* Extracts `Bamboo.Phoenix` module from `bamboo` into `bamboo_phoenix` ([66ac36305])

[66ac36305]: https://github.com/thoughtbot/bamboo_phoenix/commit/66ac363051123f925f63ad361b51679afd303265
[1.0.0]: https://github.com/thoughtbot/bamboo_phoenix/releases/tag/v1.0.0
