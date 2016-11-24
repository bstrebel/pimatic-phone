module.exports = (env) =>

  Promise = env.require 'bluebird'
  t = env.require('decl-api').types

  class PhonePlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      @timeformat = @config.timeformat
      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'PhoneDevice',
        configDef: deviceConfigDef.PhoneDevice
        createCallback: (config, lastState) =>
          return new PhoneDevice(config, lastState)

  plugin = new PhonePlugin


  class PhoneDevice extends env.devices.Device

    attributes:
      timeStamp:
        label: "Update timestamp"
        description: "UTC Timestamp (seconds) of the last location update."
        type: t.number
        unit: "s"
        acronym: 'UTC'
        displaySparkline: false
        hidden: true
      timeSpec:
        label: "Update time spec"
        description: "Date and time of the last location update."
        type: t.string
        unit: ""
        acronym: 'DT'
        displaySparkline: false
        hidden: false
      locationTag:
        description: "Current location of the device"
        type: t.string
        unit: ""
        acronym: 'LOC'
        displaySparkline: false
        hidden: false

    actions:
      updateLocationTag:
        description: "Update location tag of device"
        params:
          tag:
            type: "string"

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @serial = @config.serial
      @debug = plugin.debug || false
      @timeformat = plugin.timeformat

      @_locationTag = lastState?.locationTag?.value or "UNKNOWN"
      if not lastState?.timeStamp?.value
        timestamp = new Date()
        @_timeSpec = timestamp.format(@timeformat)
        @_timeStamp = parseInt(timestamp.getTime()/1000, 10)

      super()

    destroy: () ->
      super()

    getLocationTag: () -> Promise.resolve(@_locationTag)
    getTimeStamp: () -> Promise.resolve(@_timeStamp)
    getTimeSpec: () -> Promise.resolve(@_timeSpec)
    getSerial: () -> Promise.resolve(@_serial)

    updateLocationTag: (tag) ->
      timestamp = new Date()
      @_timeSpec = timestamp.format(@timeformat)
      @_timeStamp = parseInt(timestamp.getTime()/1000, 10)
      @_locationTag = tag
      @emit 'locationTag', @_locationTag
      @emit 'timeStamp', @_timeStamp
      @emit 'timeSpec', @_timeSpec
      env.logger.info('Update location for ' + @name + ': ' + tag)

      return Promise.resolve()

  return plugin
