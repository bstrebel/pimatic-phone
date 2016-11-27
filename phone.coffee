module.exports = (env) =>

  Promise = env.require 'bluebird'
  t = env.require('decl-api').types

  class PhonePlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'PhoneDevice',
        configDef: deviceConfigDef.PhoneDevice
        createCallback: (config, plugin, lastState) =>
          return new PhoneDevice(config, @, lastState)

      @framework.deviceManager.registerDeviceClass 'PhoneDeviceIOS',
        configDef: deviceConfigDef.PhoneDeviceIOS
        createCallback: (config, plugin, lastState) =>
          return new PhoneDeviceIOS(config, @, lastState)


  plugin = new PhonePlugin


  class PhoneDevice extends env.devices.Device

    attributes:
      timeStamp:
        label: "Update timestamp"
        description: "UTC Timestamp (mseconds) of the last location update."
        type: t.number
        unit: "ms"
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
      locationSource:
        label: "Location source"
        description: "Source of location information: LOC, GPS, NET, TAG, SSID"
        type: t.string
        unit: ""
        acronym: 'SRC'
        displaySparkline: false
        hidden: false
      locationTag:
        description: "Current location of the device"
        type: t.string
        unit: ""
        acronym: 'LOC'
        displaySparkline: false
        hidden: false
      latitude:
        label: "Latitude"
        description: "Latitude of device"
        type: "number"
        unit: "°"
        acronym: 'LAT'
        displaySparkline: false
        hidden: true
      longitude:
        label: "Longitude"
        description: "Longitude of device"
        type: "number"
        unit: "°"
        acronym: 'LONG'
        displaySparkline: false
        hidden: true
      accuracy:
        label: "Accuracy"
        description: "Accuracy of location data"
        type: "number"
        unit: "°"
        acronym: 'LONG'
        displaySparkline: false
        hidden: true

    # attribute getter methods
    getLocationSource: () -> Promise.resolve(@_locationSource)
    getLocationTag: () -> Promise.resolve(@_locationTag)
    getTimeStamp: () -> Promise.resolve(@_timeStamp)
    getTimeSpec: () -> Promise.resolve(@_timeStamp.format(@timeformat))
    getSerial: () -> Promise.resolve(@_serial)
    getLatitude: () -> Promise.resolve(@_latitude)
    getLongitude: () -> Promise.resolve(@_longitude)
    getAccuracy: () -> Promise.resolve(@_accuracy)

    actions:
      updateLocationTag:
        description: "Update location tag of device"
        params:
          tag:
            type: "string"
      updateLocation:
        description: "Updates GPS location of the device."
        params:
          long:
            type: "number"
          lat:
            type: "number"
          updateAddress:
            type: "number"

    constructor: (@config, plugin, lastState) ->

      # plugin configuration
      @debug = plugin.debug || false
      @timeformat = plugin.timeformat

      # device configuration
      @id = @config.id
      @name = @config.name
      @serial = @config.serial

      # device attribute initialization
      @_locationTag = lastState?.locationTag?.value or "UNKNOWN"
      @_timeStamp = lastState?.timeStamp?.value or new Date()

      super()

    destroy: () ->
      super()


    updateLocationTag: (tag) ->
      @_locationSource = "TAG"
      @_locationTag = tag

      # TODO: check valid tags or throw error
      #       set location from location tag

      env.logger.info('Update location for ' + @name + ': ' + tag)
      return @_emitUpdates()

    updateLocation: (long, lat, updateAddress) ->
      # pimatic-location android client
      @_locationSource = LOC
      @_timeStamp = new Date()
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0

      # TODO: calculate tag from location
      #

      env.logger.debug("Received: long=#{long} lat=#{lat} from #{@name} at #{timestamp}")
      return @_emitUpdates()

    _emitUpdates: () =>
      # publish the updated attributes
      @emit 'locationTag', @_locationTag
      @emit 'locationSource', @_locationSource
      @emit 'timeStamp', @_timeStamp
      @emit 'timeSpec', @_timeStamp.format(@timeformat)
      @emit 'latitude', @_latitude
      @emit 'longitude', @_longitude
      @emit 'accuracy', @_accuracy
      return Promise.resolve()

  class PhoneDeviceIOS extends PhoneDevice

    constructor: (@config, plugin, lastState) ->
      @iCloudUser = @config.iCloudUser
      @iCloudPass = @config.iCloudPass
      @iCloudDevice = @config.iCloudDevice
      @iCloudInterval = @config.iCloudInterval
      super(@config, plugin, lastState)

    destroy: () ->
      super()


  return plugin
