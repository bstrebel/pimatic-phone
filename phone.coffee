module.exports = (env) =>

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  t = env.require('decl-api').types

  class PhonePlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass('PhoneDevice', {
        configDef: deviceConfigDef.PhoneDevice,
        createCallback: (config, lastState) => new PhoneDevice(config, lastState, @)
      })

      @framework.deviceManager.registerDeviceClass('PhoneDeviceIOS', {
        configDef: deviceConfigDef.PhoneDeviceIOS,
        createCallback: (config, lastState) => new PhoneDeviceIOS(config, lastState, @)
      })

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
        discrete: true
      timeSpec:
        label: "Update time spec"
        description: "Date and time of the last location update."
        type: t.string
        unit: ""
        acronym: 'DT'
        displaySparkline: false
        hidden: false
        discrete: true
      locationSource:
        label: "Location source"
        description: "Source of location information: LOC, GPS, NET, TAG, SSID"
        type: t.string
        unit: ""
        acronym: 'SRC'
        displaySparkline: false
        hidden: false
        discrete: true
      locationTag:
        description: "Current location of the device"
        type: t.string
        unit: ""
        acronym: 'LOC'
        displaySparkline: false
        hidden: false
        discrete: true
      latitude:
        label: "Latitude"
        description: "Latitude of device"
        type: "number"
        unit: "°"
        acronym: 'LAT'
        displaySparkline: false
        hidden: false
      longitude:
        label: "Longitude"
        description: "Longitude of device"
        type: "number"
        unit: "°"
        acronym: 'LONG'
        displaySparkline: false
        hidden: false
      accuracy:
        label: "Accuracy"
        description: "Accuracy of location data"
        type: "number"
        unit: "°"
        acronym: 'LONG'
        displaySparkline: false
        hidden: true

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

    # attribute getter methods
    getLocationSource: () -> Promise.resolve(@_locationSource)
    getLocationTag: () -> Promise.resolve(@_locationTag)
    getTimeStamp: () -> Promise.resolve(@_timeStamp)
    getTimeSpec: () -> Promise.resolve(@_timeSpec)
    getSerial: () -> Promise.resolve(@_serial)
    getLatitude: () -> Promise.resolve(@_latitude)
    getLongitude: () -> Promise.resolve(@_longitude)
    getAccuracy: () -> Promise.resolve(@_accuracy)

    constructor: (@config, lastState, plugin) ->
      # phone device configuration
      @id = @config.id
      @name = @config.name

      # get phone plugin settings
      @debug = plugin.config.debug || false
      @timeformat = plugin.config.timeformat

      # device attribute initialization
      @_serial = @config.serial

      ###
      if lastState != undefined
        # maybe undef because of flush database problems on exit
        @_locationTag = lastState.locationTag?.value or "UNKNOWN"
        @_timeStamp = lastState.timeStamp?.value or @_setTimeStamp()
      ###

      super()

    destroy: () ->
      super()

    updateLocationTag: (tag) ->
      @_setTimeStamp()
      @_locationSource = "TAG"
      @_locationTag = tag

      # TODO: check valid tags or throw error
      #       set location from location tag

      env.logger.info("Update location for #{@name}: #{tag}")
      return @_emitUpdates()

    updateLocation: (long, lat, updateAddress) ->
      # legacy action for pimatic-location android client
      @_setTimeStamp()
      @_locationSource = "LOC"
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0

      # TODO: calculate tag from location
      #

      env.logger.debug("Received: long=#{long} lat=#{lat} from #{@name} at #{@_timeStamp}")
      return @_emitUpdates()

    _emitUpdates: () ->
      # publish the updated attributes
      @emit 'locationTag', @_locationTag
      @emit 'locationSource', @_locationSource
      @emit 'timeStamp', @_timeStamp
      @emit 'timeSpec', @_timeSpec
      @emit 'latitude', @_latitude
      @emit 'longitude', @_longitude
      @emit 'accuracy', @_accuracy
      return Promise.resolve()

    _setTimeStamp: () ->
      @_timeStamp = new Date()
      @_timeSpec = @_timeStamp.format(@timeformat)
      return @_timeStamp

  class PhoneDeviceIOS extends PhoneDevice

    fmip = require 'fmip'

    constructor: (@config, lastState, plugin) ->

      super(@config, lastState, plugin)

      @iCloudUser = @config.iCloudUser
      @iCloudPass = @config.iCloudPass
      @iCloudDevice = @config.iCloudDevice
      @iCloudInterval = @config.iCloudInterval

      if @iCloudInterval > 0
        if not @iCloudUser
          env.logger.error("Missing iCloud username!")
        else
          if not @iCloudPass
            env.logger.error("Missing iCloud password for #{@iCloudUser}!")
          else
            if not @iCloudDevice
              env.logger.error("Missing iCloud device name for #{name}")
            else
              fmip.devices @iCloudUser, @iCloudPass, (error, devices) =>
                if error?
                  env.logger.error(error.message)
                else
                  if _.find(devices, 'name': @iCloudDevice)
                    env.logger.info("Found device \"#{@iCloudDevice}\" for #{@iCloudUser}")
                    @_updateDevice()
                    @intervalId = setInterval( ( =>
                      @_updateDevice()
                    ), @iCloudInterval * 1000)
                  else
                    devs = []
                    devs.push(device.name) for device in devices
                    env.logger.error("iCloud device \"#{@iCloudDevice}\" not found in [#{devs.join(', ')}]")

    destroy: () ->
      clearInterval @intervalId if @intervalId?
      super()

    _updateDevice: () ->
      fmip.device @iCloudUser, @iCloudPass, @iCloudDevice, (error, device) =>
        if error?
          env.logger.error(error.message)
        else
          location = device.location
          @updateLocation(location.longitude, location.latitude, 1)

  return plugin
