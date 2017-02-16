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

      phones = _(@framework.deviceManager.devices).values().filter(
        (device) -> device.hasAction("suspend")
      ).value()

      device = null
      suspend = null
      code = null
      match = null

      m = M(input, context).match(['suspend ', 'resume '], (m, s) ->
        suspend = s.trim() == 'suspend'
        m.matchDevice(phones, (m, d) ->
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          device = d
          match = m.getFullMatch()
          if !suspend and device?.iCloud2FA
            m.match(' with ')
            .matchStringWithVars( (m, c) ->
              code = _.clone(c)
              match = m.getFullMatch()
            )
        )
      )
      if match?
        assert device?
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SuspendActionHandler(device, suspend, code)
        }
      else
        return null


  ############################################################
  class SuspendActionHandler extends env.actions.ActionHandler
  #############################################################

    constructor: (@device, @suspend, @code) ->

    setup: ->
      @dependOnDevice(@device)
      super()

    _doExecuteAction: (simulate, suspend, code) =>
      return (
        if simulate
          Promise.resolve("would set suspend of #{@device.id} to #{suspend}")
        else
          if @device.iCloud2FA
            if suspend
              @device.disableUpdates().then(  =>
                Promise.resolve("disable updates for #{@device.id}" )
              )
            else
              if code.length == 1
                _code = code[0].trim().replace(/"/g, "")
              else if code.length == 3 and code[1].startsWith('$')
                _code = code[1]
              else
                _code = '000000'
              @device.enableUpdates(_code).then( (response) =>
                Promise.resolve("enable updates for #{@device.id} with #{_code}" )
              )
          else
            action = if suspend then "suspend" else "resume"
            @device.suspend(suspend.toString()).then( =>
              Promise.resolve("#{action} #{@device.id}")
            )
      )

    executeAction: (simulate) => @_doExecuteAction(simulate, @suspend, @code)
    hasRestoreAction: -> no
    # executeRestoreAction: (simulate) => @_doExecuteAction(simulate, (not @suspend), @code)


  ##################################################################
  class SetLocationActionProvider extends env.actions.ActionProvider
  ##################################################################

    constructor: (@framework) ->

    parseAction: (input, context) ->
      retVar = null

      phones = _(@framework.deviceManager.devices).values().filter(
        (device) -> device.hasAction("updateTag")
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
          Promise.resolve __("would set location of %s to %", @device.id, tag)
        else
          @device.updateTag(tag).then(  =>
            __("set location of %s to %s", @device.id, tag)
          )
      )

    executeAction: (simulate) => @_doExecuteAction(simulate, @tag)
    hasRestoreAction: -> no
    #executeRestoreAction: (simulate) => @_doExecuteAction(simulate, (not @tag))


  return exports = {
    SetSuspendActionProvider
    SetLocationActionProvider
  }