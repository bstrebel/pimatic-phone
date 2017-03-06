module.exports = (env) ->

  __ = env.require("i18n").__
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require('lodash')
  S = env.require('string')
  M = env.matcher


  ###
  The Device-Attribute Predicate Provider
  ----------------
  Handles predicates for comparing device attributes like sensor values or other states:

  * distance of _device_ to _location_ is equal to _value_
  * _attribute_ of _device_ equals _value_
  * _attribute_ of _device_ is not _value_
  * _attribute_ of _device_ is less than _value_
  * _attribute_ of _device_ is lower than _value_
  * _attribute_ of _device_ is greater than _value_
  * _attribute_ of _device_ is higher than _value_
  ####
  class DeviceAttributePredicateProvider extends PredicateProvider

    presets: [
      {
        name: "distance of a device"
        input: "{distance} of {device} to {location} is equal to {value}"
      }
    ]

    constructor: (@framework) ->

    parsePredicate: (input, context) ->

      allDistances = ['distance', 'route', 'eta']
      result = null
      matches = []

      M(input, context)
        .match(allDistances, param: "distance", wildcard: "{distance}", (m, _distance) =>
          info = {
            device: null
            attributeName: null
            comparator: null
            referenceValue: null
          }
          info.distanceName = _distance
          devices = _(@framework.deviceManager.devices).values()
            .filter((device) => device.hasAttribute('location')).value()

          m.match(' from ').matchDevice(devices, (next, device) =>
            info.device = device
            unless device.hasAttribute(attr) then return
            attribute = device.attributes[attr]
            setComparator =  (m, c) => info.comparator = c
            setRefValue = (m, v) => info.referenceValue = v
            end =  => matchCount++

            m = next.matchComparator('number', setComparator)
              .matchNumber(wildcard: '{value}', (m,v) => setRefValue(m, parseFloat(v)) )
            if attribute.unit? and attribute.unit.length > 0
              possibleUnits = _.uniq([
                " #{attribute.unit}",
                "#{attribute.unit}",
                "#{attribute.unit.toLowerCase()}",
                " #{attribute.unit.toLowerCase()}",
                "#{attribute.unit.replace('°', '')}",
                " #{attribute.unit.replace('°', '')}",
                "#{attribute.unit.toLowerCase().replace('°', '')}",
                " #{attribute.unit.toLowerCase().replace('°', '')}",
              ])
              autocompleteFilter = (v) => v is " #{attribute.unit}"
              m = m.match(possibleUnits, {optional: yes, acFilter: autocompleteFilter})

            if m.hadMatch()
              matches.push m.getFullMatch()
              if result?
                if result.device.id isnt info.device.id or
                  result.attributeName isnt info.attributeName
                  context?.addError(""""#{input.trim()}" is ambiguous.""")
              result = info
          )
      )

      if result?
        assert result.device?
        assert result.attributeName?
        assert result.comparator?
        assert result.referenceValue?
        # take the longest match
        match = _(matches).sortBy( (s) => s.length ).last()
        assert typeof match is "string"

        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new DeviceAttributePredicateHandler(
            result.device, result.attributeName, result.comparator, result.referenceValue
          )
        }

      return null


  class DeviceAttributePredicateHandler extends PredicateHandler

    constructor: (@device, @attribute, @comparator, @referenceValue) ->
      @dependOnDevice(@device)

    setup: ->
      lastState = null
      @attributeListener = (value) =>
        state = @_compareValues(@comparator, value, @referenceValue)
        if state isnt lastState
          lastState = state
          @emit 'change', state
      @device.on @attribute, @attributeListener
      super()
    getValue: ->
      @device.getUpdatedAttributeValue(@attribute).then( (value) =>
        @_compareValues(@comparator, value, @referenceValue)
      )
    destroy: ->
      @device.removeListener @attribute, @attributeListener
      super()
    getType: -> 'state'

# ### _compareValues()
    ###
    Does the comparison.
    ###
    _compareValues: (comparator, value, referenceValue) ->
      if typeof referenceValue is "number"
        value = parseFloat(value)
      result = switch comparator
        when '==' then value is referenceValue
        when '!=' then value isnt referenceValue
        when '<' then value < referenceValue
        when '>' then value > referenceValue
        when '<=' then value <= referenceValue
        when '>=' then value >= referenceValue
        else throw new Error "Unknown comparator: #{comparator}"
      return result





  class DistanceEventProvider extends env.predicates.PredicateProvider

    constructor: (@framework) ->

    parsePredicate: (input, context) ->

      phones = _(@framework.deviceManager.devices).values()
        .filter((device) => device.hasAttribute('tag')).value()

      locations = ['Home', 'Office']

      phone = null
      location = null

      setPhone = (m, match) => phone = match.trim()
      setTag = (m, match) => tag = match.trim()
      setFieldValue = (m, match) => fieldValue = match.trim()
      setEventType = (m, match) => eventType = match.trim()

      m = M(input, context)
        .match('distance from ')
        .matchDevice(phones, setPhone)
        .match(' to ')
        .match(tags, setTag)

      if m.hadMatch()
        fullMatch = m.getFullMatch()
        return {
          token: fullMatch
          nextInput: input.substring(fullMatch.length)
          predicateHandler: new CalendarEventHandler(
            field, fieldValue, checkType, eventType
          )
        }
      else
        return null


  class CalendarEventHandler extends env.predicates.PredicateHandler

    constructor: (@field, @fieldValue, @checkType, @eventType) ->
      @state = null

    setup: ->
      calPlugin.on 'event-start', @onEventStart = (info) =>
        if @eventType is 'starts'
          if @_doesMatch info
            @emit 'change', 'event'
        else if @eventType is 'takes place'
          if @_doesMatch info
            @state = true
            @emit 'change', true

      calPlugin.on 'event-end', @onEventEnd = (info) =>
        if @eventType is 'ends'
          if @_doesMatch info
            @emit 'change', 'event'
        else if @eventType is 'takes place'
          if @_doesMatch info
            @state = false
            @emit 'change', false
      super()

    _doesMatch: (info) ->
      eventValue = null
      if @field is 'title'
        eventValue = info.event.summary
      else if @field is 'description'
        eventValue = info.event.description
      if @checkType is 'equals' and eventValue is @fieldValue
        return true
      if @checkType is 'contains' and eventValue.indexOf(@fieldValue) isnt -1
        return true
      return false

    getType: -> if @eventType is 'takes place' then 'state' else 'event'

    getValue: -> Promise.resolve(@state is true)

    destroy: ->
      calPlugin.removeListener 'event-start', @onEventStart
      calPlugin.removeListener 'event-end', @onEventEnd
      super()






  return exports = {
    SetSuspendActionProvider
    SetLocationActionProvider
    SetAddressActionProvider
  }