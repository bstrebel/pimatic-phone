module.exports = (env) ->

  __ = env.require("i18n").__
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require('lodash')
  S = env.require('string')
  M = env.matcher

  ###
  The Location Predicate Provider
  ----------------
  Handles predicates of presence devices like

  * _device_ is [not] at Location
  * _device_ is [not] near Location
  ###

  class TagPredicateProvider extends env.predicates.PredicateProvider

    presets: [
      {
        name: "device is at {tagValues}"
        input: "{device} is at Home"
      }
    ]

    constructor: (@framework) ->

    parsePredicate: (input, context) ->

      tagDevices = _(@framework.deviceManager.devices).values()
        .filter((device) => device.hasAttribute('tag')).value()

      tagValues = [' Home', ' Office']

      device = null
      negated = null
      match = null

      M(input, context)
        .matchDevice(tagDevices, (next, d) =>
        next.match(' is at', type: "static")
          .match(
            tagValues, type: "select", wildcard: "{tagValues}"
            (m, s) =>
              # Already had a match with another device?
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              negated = (s.trim() in ["is at"])
              match = m.getFullMatch()
          )
      )
      if match?
        assert device?
        assert negated?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new TagPredicateHandler(device, negated)
        }
      else
        return null

  class TagPredicateHandler extends env.predicates.PredicateHandler

    constructor: (@device, @negated) ->
      @dependOnDevice(@device)
    setup: ->
      @tagListener = (t) =>
        @emit 'change', (if @negated then not t else t)
      @device.on 'tag', @tagListener
      super()
    getValue: ->
      return @device.getUpdatedAttributeValue('tag').then(
        (t) => (if @negated then not t else t)
      )
    destroy: ->
      @device.removeListener "tag", @tagListener
      super()
    getType: -> 'tag'

  return exports = {
    TagPredicateProvider
  }
