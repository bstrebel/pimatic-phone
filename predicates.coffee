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
  Handles predicates of phone devices like

  * _device_ is [not] at Location
  * _device_ is [not] near Location
  ###

  class TagPredicateProvider extends PredicateProvider

    constructor: (@framework) ->

    parsePredicate: (input, context) ->

      tagDevices = _(@framework.deviceManager.devices).values()
        .filter((device) -> device.hasAttribute( 'tag')).value()

      tagValues = [' Home', ' Office']

      device = null
      match = null

      M(input, context)
        .matchDevice(tagDevices, (m, d) ->
          m.match([' is at'], type: "static")
            .match(tagValues, (m, t) ->
              # Already had a match with another device?
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              tag = t.trim()
              match = m.getFullMatch()
            )
      )

      if match?
        assert device?
        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new TagPredicateHandler(device, tag)
        }
      else
        return null

  class TagPredicateHandler extends PredicateHandler

    constructor: (@device, @tag) ->
      @dependOnDevice(@device)
    setup: ->
      @tagListener = (t) =>
        @emit 'change', ()
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
