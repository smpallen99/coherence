# Coherence Changelog

## 0.6.0 (2018-09-xx)

See these [0.5.x to 0.6.x upgrade instructions](https://gist.github.com/smpallen99/fc59423d521f7f6773a5fa9236512faf) to upgrade your existing apps.

* Enhancements
  * Moved Controller actions and helpers into a base modules inside __using__ macro to improve upgrades with custom controllers
  * Add configurable salt and max_age for tokens
  * Add default opts for token functions
  * Add support for application configurable confirmable
  * Support code formatter formatter
  * Add logging to the mailer template
  * Updated to Comeonin 4.0
  * Add support for configurable password hashing algorithms
  * Speed up tests by configuring the Bcrypt algorithm
  * Format may generator templates to align with code formatter

* Bug Fixes
  * Fixed detection of remember me checkbox on session new page
  * Fixed compiled gettext in view helpers
  * Fix new session screen issue on newly generated project #390
  * Add back the gettext fix in ViewHelpers

* Deprecations
  * Removed the coherence.make_templates task since its no longer needed with the new controller design

* Hard Deprecations
  * Removed support for erlang < 20.0
  * Removed support for pre Phoenix 1.3 project structure
    * removed `coherence.install` and `coherence.gen.controllers` mix tasks

## 0.5.2 (2018-09-03)

* Enhancements
  * Added default permitted attributes to help with upgrades #371

## 0.5.1 (2018-08-28)

* Enhancements
  * Add new `coh.gen.controllers` generator
  * `coh.clean` task now supports phx and phoenix projects
  * Renamed `Coherence.ControllerHelpers` module to `Coherence.Controller`
  * Update timex and timex_ecto dependency versions. closes #333
  * Added new update_user_login/1 function
  * Added new `allowed attributes` feature to protect against allowing accesses to internal schema fields.
  * Update uuid dependency version
  * Allow silent password recovery for unknown users

* Bug Fixes
  * Fixed issues with generated controllers
  * Fixed issues with clean tasks
  * Fixed localization of view helpers. closes #322 and closes #327
  * Fixed incorrect logic for custom password changeset. closes #351
  * Fixed config return type for email_reply_to. closes #227
  * Fixed :peer retrieval issue with new Plug.Conn
  * Fixed issue attempting to immediately log in after registering an account
  * Fix in password controller to support subdomains

* Backward incompatible changes
  * `--controllers` option is not supported for the install tasks
  * removed the `coherence.clean` task
  * Need to update `seeds.exs` if your using confirmable option

## 0.5.0 (2017-08-03)

* Enhancements
  * Support the released Version of Phoenix 1.3 project structure
  * Project name spaced generated view modules
  * GenServer based Session Store
    * Single user model stored for multiple logins of the same user
    * Support to update user model for all logged in sessions
  * add --web-module installer option
  * Generate Invitation, Rememberable, and Trackable schemas
  * Use app's layout by default. Use --layout option to generate and use a specific layout for coherence. #186
  * Remove login callback and replace with Phoenix.Controller.redirect. #254
  # Add support for active field in user schema. #201

* Bug Fixes
  * Fixed incorrect reference to CoherenceDemo in Config.mailer?
  * Proper support for binary_ids

* Backward incompatible changes
  * Does not support Phoenix 1.3.0-rc versions with lib/my_project/web project structure
  * Previous generated controllers and views must be updated

## 0.4.0 (2017-07-03)

See these `0.3.1` to `0.4.0` [upgrade instructions](https://gist.github.com/smpallen99/92d826b6f523edd83b4a358cf05e97e7) to bring your existing app up to speed.

* Enhancements
  * Localization with Gettext
  * Support the new `Phoenix 1.3` project structure created with `mix phx.new`. Use `mix coh.install`
  * Support for legacy projects with the `mix coherence.install` task
  * Callback to redirect invitation resend
  * Add use_binary_id config
  * Use the binary_id generators setting in your project
  * Remove most of the Credo warnings
  * Support user tokens for channel authentication
  * Removed compiler warnings for Elixir 1.4
  * Change datetime to utc_datetime
  * Added new trackable-table option to reduce noise in user schema
  * Track login and logout in trackable-table
  * Added specs and resolved many dialyzer warnings
  * Added asyc_rememberable? support for near concurrent Ajax requests
  * Don't increment rememberable sequence number for Ajax requests
  * Added support for custom layouts
  * Added configurable require current password to change passwords
  * Added support for fast switch user (no password required) in dev environment only

* Bug Fixes
  * Fix session controller when lockable is false
  * Make remember me clickable
  * Fixed layout for unauthenticated protected routes
  * Fixed race conditions in rememberable callback

* Backwards incompatible changes
  * coherence config requires `:messages_backend` field to be set (MyProject.Coherence.Messages)
  * coherence_messages.ex file must be generated and included in our app. Done by the installer
  * coherence config requires `:router` field to be set (MyProject.Web.Router)

## 0.3.1  (2016-11-26)

See these `0.3.0` to `0.3.1` [upgrade instructions](https://gist.github.com/smpallen99/2241d3365aedf0ca3eb884f16def0bb1) to bring your existing app up to speed.

* Enhancements
  * Remove unused params from registration path
  * Update docs for coherence_links
  * Add unit tests for registration controller
  * Support unconfirmed access
  * Support auto login if unconfirmed access is enabled
  * Start refactoring into schema modules (web/models/confirmable.ex)
  * Raise compiler error when protected routes are defined before public routes
  * Add current_user and logged_in? view helpers
  * Add templates customization section
  * Add Config.logged_in_url to be used for redirect from redirect_logged_in plug
  * Add :coherence to apps in installer instructions
  * Add sign in link helper
  * Validate email format with some minor improvements
  * Document customizable actions
  * Allow configuring specific routes
  * Add signout_link function to view helpers
  * Support {:system, env_var} in config
  * Add new `mix coherence.install --reinstall` option
  * Add `--silent`, `--confirm-once`, and `--no-confirm` option to `mix coherence.install`

* Bug Fixes
  * Remove web/controllers/redirects since it breaks releases
  * Fix readme getting started section
  * Ensure local module is loaded on login callback
  * Give correct HTTP status code when login fail

* Deprecations
  * email_from config - use  email_from_name and email_from_email
  * email_reply_to config - use email_reply_to_name and email_reply_to_email

* Backward incompatible changes

## 0.3.0  (2016-08-28)

See these `0.2.0` to `0.3.0` [upgrade instructions](https://gist.github.com/smpallen99/ae80753a5cdea5d20a1c03639b9a801e) to bring your existing app up to speed.

* Enhancements
  * All controller redirects are now customizable
  * Logged in users trying to view pages meant for unauthenticated users now get redirected to logged_out_url (session new, register new, etc.)
  * Support resend confirmation instructions
  * Support custom changesets
  * Make routes more intuitive
  * `--install-options` mix task option

* Bug Fixes
  * rename database column `confirmation_send_at` `to confirmation_sent_at`
  * fix an coherence.clean --all doing a dry-run
  * fix router install instructions
  * install instructions include confirm! for seeds file

* Deprecations
  * `coherence_routes :public` is replaced with `coherence_routes`
  * `coherence_routes :private` is replaced with `coherence_routes :protected`

* Backward incompatible changes
  * `coherence_routes` has changed from default `:all` to public routes
  * the rename of database column `confirmation_send_at` `to confirmation_sent_at` requires that you generate a new migration to alter the table.

## 0.2.0  (2016-7-30)

* Enhancements
  * Support Token Authentication
  * Support IP Address Authentication
  * Support ability to clean specific options from an install

* Bug Fixes
  * Fix compile issue with trackable and not lockable
  * Fix incorrect config installer instructions
  * Fix types in README file

* Deprecations
  * None

* Backward incompatible changes
  * the schema change `confirmation_sent_at` will require updating the  user model database. You should create a migration to alter the table.

## 0.1.3  (2016-7-18)

* Bug Fixes
  * Use rememberable token when session dies

* Deprecations
  * User.confirm!/1 - use Coherence.ControllerHelpers.confirm!/1
  * User.lock!/1 - use Coherence.ControllerHelpers.lock!/1
  * User.unlock!/1 - use Coherence.ControllerHelpers.unlock!/1

## 0.1.2  (2016-7-12)

* Enhancements
  * Added configurable login field to templates and controllers
  * Support Ecto 2 cast and validations
  * Schema.confirm! now return error if already confirmed
  * Add CONTRIBUTING.md
  * Enhancements to ViewHelpers.coherence_links
  * Add more tests
  * Added more docs and fix some formating issues

* Bug Fixes
  * Fix schema validation issue when passord_hash is set in config
  * Add dummy Schema.validate_coherence when authentication option is not enabled
  * Fix installer not detecting existing user model

## 0.1.1  (2016-7-11)

* Enhancements
  * Added CHANGELOG.md file

* Bug Fixes
  * Fixed some documentation issues
  * Fixed issue where install after clean does not compile with missing route helpers

* Backward incompatible changes
  * Changed user database field `hashed_password` to password_hash`
