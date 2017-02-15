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
          if state then @device._suspendState(state).then( =>
            __("set suspend of %s to true", @device.name) )
          else @device._suspendState(state).then( =>
            __("set suspend %s to false", @device.name) )
      )

    executeAction: (simulate) => @_doExecuteAction(simulate, @state)
    hasRestoreAction: -> yes
    executeRestoreAction: (simulate) => @_doExecuteAction(simulate, (not @state))

  ##################################################################
  class SetLocationActionProvider extends env.actions.ActionProvider
  ##################################################################

    constructor: (@framework) ->

    parseAction: (input, context) ->
      retVar = null

      phones = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("updateTag")
      ).value()

      tags = _.map(@framework.pluginManager.getPluginConfig('phone').locations,
        (location) -> return ' ' + location.tag)

      device = null
      tag = null
      match = null

      m = M(input, context).match(['set location of ', 'set tag of '])
      m.matchDevice(phones, (m, _device) ->
        m.match(' to', (m) ->
          m.match(tags, (m, _tag) ->
            # Already had a match with another device?
            if device? and device.id isnt _device.id
              context?.addError(""""#{input.trim()}" is ambiguous.""")
              return
            device = _device
            tag = _tag.trim().replace('to ','')
            match = m.getFullMatch()
          )
        )
      )

      if match?
        assert device?
        assert tag in _.map @framework.pluginManager.getPluginConfig('phone').locations, 'tag'
        assert typeof match is "string"

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new LocationActionHandler(device, tag)
        }
      else
        return null

  class LocationActionHandler extends env.actions.ActionHandler

    constructor: (@device, @tag) ->

    setup: ->
      @dependOnDevice(@device)
      super()

    _doExecuteAction: (simulate, tag) =>
      return (
        if simulate
          Promise.resolve __("would set location of [%s] to [%]", @device.name, tag)
        else
          @device.updateTag(tag).then( (response) =>
            __("set location of [%s] to [%s]", @device.name) )
      )

    executeAction: (simulate) => @_doExecuteAction(simulate, @tag)
    hasRestoreAction: -> yes
    executeRestoreAction: (simulate) => @_doExecuteAction(simulate, (not @tag))



  return exports = {
    SetSuspendActionProvider
    SetLocationActionProvider
  }