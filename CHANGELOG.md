# Runbook Changelog

This log maintains a list of all substantive changes to Runbook. The log includes changes in reverse chronological order.

## master

## `v0.12.0` (2019-05-16)

### Fixes:

* Fix jump backwards dynamic statement bug

### New Features

* Add attempts counter to assert statement
* Add capture_all statement

## `v0.11.0` (2019-03-26)

### Breaking Changes:

* Runbooks no longer require explicit registration using `Runbook.books[:book] = book`. This declaration will fail and is no longer necessary. It should be removed. Additionally if you are retrieving runbooks using `Runbook.books`, it's implementation has changed from a hash to an array. You should access elements using an index, not with a key.

### Potentially Breaking Changes:

* Steps without titles no longer prompt in paranoid mode. Consequently users may be taken off guard by no receiving a prompt to execute these steps. A workaround is to pass an empty string as a title if you still want these steps to prompt.

### Fixes:

* Fix bug in Thor usage
* Fix config file load ordering to support extending configuration
* Fix bug preventing assert statement from checking multiple times

### New Features

* Retry confirm statement when bad input is received
* Add additional output when running capture statement
* Automatically clear panes when cd'ing to new directory during layout statement
* Allow metadata[:toolbox] to be set dynamically
* Do not prompt for steps without titles in paranoid mode
