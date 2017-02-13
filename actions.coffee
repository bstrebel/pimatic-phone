###
Action Provider
=================
A Action Provider can parse a action of a rule string and returns an Action Handler for that.
The Action Handler offers a `executeAction` method to execute the action.
For actions and rule explanations take a look at the [rules file](rules.html).
###

__ = require("i18n").__
Promise = require 'bluebird'
assert = require 'cassert'
_ = require('lodash')
S = require('string')
M = require './matcher'

module.exports = (env) ->

