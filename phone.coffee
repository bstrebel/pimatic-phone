module.exports = (env) =>

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  t = env.require('decl-api').types

  geolib = require 'geolib'

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

    tagFromGPS: (position) =>
      if position?
        for location in @config.locations
          if location.gpss?
            for gps in location.gpss
              try
                if geolib.isPointInCircle(position, gps, gps.radius)
                  return location.tag
              catch error
                env.logger.error(error.message)
      return "unknown"

    tagFromSSID: (ssid) =>
      if ssid?
        for location in @config.locations
          if location.ssids?
            if location.ssids.indexOf(ssid) > -1
              return location.tag
      return "unknown"

    tagFromCID: (cid) =>
      if cid?
        for location in @config.locations
          if location.cids?
            if location.cids.indexOf(cid) > -1
              return location.tag
      return "unknown"

    isValidTag: (tag) =>
      if tag?
        return _.find(@config.locations, 'tag': tag)?
      return false


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
      source:
        label: "Location source"
        description: "Source of location information: LOC, GPS, NET, TAG, SSID, ..."
        type: t.string
        unit: ""
        acronym: 'SRC'
        displaySparkline: false
        hidden: false
        discrete: true
      tag:
        description: "Current location of the device"
        type: t.string
        unit: ""
        acronym: 'LOC'
        displaySparkline: false
        hidden: false
        discrete: true
      type:
        label: "Type"
        description: "Type of position data"
        type: t.string
        unit: ""
        acronym: 'TYP'
        displaySparkline: false
        hidden: false
      latitude:
        label: "Latitude"
        description: "Latitude of device"
        type: t.number
        unit: "°"
        acronym: 'LAT'
        displaySparkline: false
        hidden: false
      longitude:
        label: "Longitude"
        description: "Longitude of device"
        type: t.number
        unit: "°"
        acronym: 'LONG'
        displaySparkline: false
        hidden: false
      accuracy:
        label: "Accuracy"
        description: "Accuracy of location data"
        type: t.number
        unit: "m"
        acronym: 'ACC'
        displaySparkline: false
        hidden: true
      cell:
        label: "Cell"
        description: "Cell ID"
        type: t.string
        unit: ""
        acronym: 'CELL'
        displaySparkline: false
        hidden: true
      ssid:
        label: "SSID"
        description: "WLAN SSID"
        type: t.string
        unit: ""
        acronym: 'SSID'
        displaySparkline: false
        hidden: true
      gps:
        label: "GPS"
        description: "GPS"
        type: t.string
        unit: ""
        acronym: 'GPS'
        displaySparkline: false
        hidden: true

    actions:
      update:
        decription: "Variable update record"
        params:
          record:
            type: t.string
      updateTag:
        description: "Update location tag of device"
        params:
          tag:
            type: t.string
      updateGPS:
        description: "Update geo location values"
        params:
          latitude:
            type: t.number
          longitude:
            type: t.number
          accuracy:
            type: t.number
          source:
            type: t.string
      updateCID:
        description: "Update mobile cell id"
        params:
          cell: t.string
      updateSSID:
        description: "Update location from WLAN connection"
        params:
          ssid: t.string
      updateLocation:
        description: "Legacy: pimatic-location Android app"
        params:
          long:
            type: t.number
          lat:
            type: t.number
          updateAddress:
            type: t.number

    # attribute getter methods
    getSource: () -> Promise.resolve(@_source)
    getTag: () -> Promise.resolve(@_tag)
    getTimeStamp: () -> Promise.resolve(@_timeStamp)
    getTimeSpec: () -> Promise.resolve(@_timeSpec)
    getSerial: () -> Promise.resolve(@_serial)
    getLatitude: () -> Promise.resolve(@_latitude)
    getLongitude: () -> Promise.resolve(@_longitude)
    getAccuracy: () -> Promise.resolve(@_accuracy)
    getType: () -> Promise.resolve(@_type)
    getCell: () -> Promise.resolve(@_cell)
    getSsid: () -> Promise.resolve(@_ssid)
    getGps: () -> Promise.resolve({"latitude": @_latitude, "longitude": @_longitude}.toString())

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
        @_tag = lastState.tag?.value or "UNKNOWN"
        @_timeStamp = lastState.timeStamp?.value or @_setTimeStamp()
      ###

      super()

    destroy: () ->
      super()

    update: (record) ->
      @_setTimeStamp()
      # TODO: process update record


    updateTag: (tag) ->
      if tag?
        if plugin.isValidTag(tag)
          @_setTimeStamp()
          @_source = "TAG"
          @_tag = tag
          return @_emitUpdates("Update location for #{@name}: TAG:#{@_tag}")
        else
          env.logger.warn("Ignoring update:  TAG:#{tag}")


    updateGPS: (latitude, longitude, accuracy, type) ->
      @_setTimeStamp()
      @_source = "GPS"
      @_latitude = latitude
      @_longitude = longitude
      @_accuracy = accuracy
      @_type = type
      @_tag = plugin.tagFromGPS({"latitude": latitude, "longitude": longitude})
      return @_emitUpdates("Update location for #{@name}: GPS:#{@_latitude},#{@_longitude},#{@_accuracy}")

    updateCID: (cell) ->
      @_setTimeStamp()
      @_source = "CID"
      @_cell = cell
      @_tag = plugin.tagFromCID(cell)
      return @_emitUpdates("Update location for #{@name}: #{@_cell}")

    updateSSID: (ssid) ->
      @_setTimeStamp()
      @_source = "SSID"
      @_ssid = ssid
      @_tag = plugin.tagFromSSID(ssid)
      return @_emitUpdates("Update location for #{@name}: SSID:#{@_ssid}")

    updateLocation: (long, lat, updateAddress) ->
      # legacy action for pimatic-location android client
      @_setTimeStamp()
      @_source = "LOC"
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0
      @_tag = plugin.tagFromGPS({"latitude": lat, "longitude": long})
      return @_emitUpdates("Update location for #{@name}: GPS:#{@_latitude},#{@_longitude}")

    _emitUpdates: (logMsg) ->
      env.logger.debug(logMsg)

      # publish the updated attributes
      @emit 'tag', @_tag
      @emit 'source', @_source
      @emit 'timeStamp', @_timeStamp
      @emit 'timeSpec', @_timeSpec
      @emit 'latitude', @_latitude
      @emit 'longitude', @_longitude
      @emit 'accuracy', @_accuracy
      @emit 'type', @_type
      @emit 'cell', @_cell
      @emit 'ssid', @_ssid

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
          @updateGPS(location.latitude, location.longitude, location.horizontalAccuracy, location.positionType)

  return plugin
