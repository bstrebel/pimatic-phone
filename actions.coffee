###
The Suspend ActionProvider
-------------
Provides set suspend action, so that rules can use `set suspend of <device> to true|false`
in the actions part.
###

module.exports = (env) ->

  __ = env.require("i18n").__
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require('lodash')
  S = env.require('string')
  M = env.matcher

  #################################################################
  class SetSuspendActionProvider extends env.actions.ActionProvider
  #################################################################

    constructor: (@framework) ->

    parseAction: (input, context) ->

      retVar = null
      phones = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("suspend")
      ).value()

      device = null
      state = null
      match = null

      # Try to match the input string with:
      M(input, context)
      .match(['suspend ', 'resume '], (next, flag) =>
        next.matchDevice(phones, (next, d) =>
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          device = d
          state = (flag.trim() is 'suspend')
          match = next.getFullMatch()
        )
      )

      if match?
        assert device?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SuspendActionHandler(device, state)
        }
      else
        return null


  ############################################################
  class SuspendActionHandler extends env.actions.ActionHandler
  #############################################################

    constructor: (@device, @state) ->

    setup: ->
      @dependOnDevice(@device)
      super()

    _doExecuteAction: (simulate, state) =>
      return (
        if simulate
          if state then Promise.resolve __("would set suspend of %s to true", @device.name)
          else Promise.resolve __("would set suspend of %s to false", @device.name)
        else
          if state then @device.suspend(state).then( =>
            __("set suspend of %s to true", @device.name) )
          else @device.suspend(state).then( =>
            __("set suspend %s to false", @device.name) )
      )

    executeAction: (simulate) => @_doExecuteAction(simulate, @state)
    hasRestoreAction: -> yes
    executeRestoreAction: (simulate) => @_doExecuteAction(simulate, (not @state))

  return exports = {
    SetSuspendActionProvider
  }