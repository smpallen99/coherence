# Changelog

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
