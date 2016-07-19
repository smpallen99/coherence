# Changelog

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
