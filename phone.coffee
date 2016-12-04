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

    tagFromGPS: (position, accuracy) =>
      if position?
        for location in @config.locations
          if location.gps?
            gps = location.gps
            radius = if accuracy > 0 then accuracy else gps.radius
            try
              if geolib.isPointInCircle(position, gps, radius)
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

    locationFromTag: (tag) =>
      if tag?
        return _.find(@config.locations, 'tag': tag)

  plugin = new PhonePlugin


  class PhoneDevice extends env.devices.Device

    attributes:
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
    getTimeSpec: () -> Promise.resolve(@_timeSpec)
    getSerial: () -> Promise.resolve(@_serial)
    getLatitude: () -> Promise.resolve(@_latitude)
    getLongitude: () -> Promise.resolve(@_longitude)
    getAccuracy: () -> Promise.resolve(@_accuracy)
    getType: () -> Promise.resolve(@_type)
    getCell: () -> Promise.resolve(@_cell)
    getSsid: () -> Promise.resolve(@_ssid)
    getGps: () -> Promise.resolve(@_gps)

    constructor: (@config, lastState, plugin) ->
      # phone device configuration
      @id = @config.id
      @name = @config.name

      # get phone plugin settings
      # @debug = plugin.config.debug || false
      @timeformat = plugin.config.timeformat

      # use device specific debug flag
      # to allow changes during runtime
      @debug = @config.debug || false
      @accuracy = @config.accuracy

      # device attribute initialization
      @_serial = @config.serial

      super()

    destroy: () ->
      super()

    update: (record) ->
      @_setTimeStamp()
      # TODO: process update record

    updateTag: (tag) ->
      @_setTimeStamp()
      @_source = "TAG"
      @_tag = tag
      @_type = "API"
      location = plugin.locationFromTag(@_tag)
      @_latitude = location?.gps?.latitude or 0
      @_longitude = location?.gps?.longitude or 0
      return @_emitUpdates("Update location for #{@name}: TAG:#{@_tag}")

    updateGPS: (latitude, longitude, accuracy, type) ->
      @_setTimeStamp()
      @_source = "GPS"
      @_latitude = latitude
      @_longitude = longitude
      @_accuracy = accuracy
      @_type = type
      @_gps = JSON.stringify({"latitude": @_latitude, "longitude": @_longitude, "accuracy": @_accuracy})
      @_tag = plugin.tagFromGPS({"latitude": latitude, "longitude": longitude}, @accuracy)
      return @_emitUpdates("Update location for #{@name}: GPS:#{@_latitude},#{@_longitude},#{@_accuracy}")

    updateCID: (cell) ->
      @_setTimeStamp()
      @_source = "CID"
      @_cell = cell
      @_type = "CID"
      @_tag = plugin.tagFromCID(cell)
      location = plugin.locationFromTag(@_tag)
      @_latitude = location?.gps?.latitude or 0
      @_longitude = location?.gps?.longitude or 0
      return @_emitUpdates("Update location for #{@name}: #{@_cell}")

    updateSSID: (ssid) ->
      @_setTimeStamp()
      @_source = "SSID"
      @_ssid = ssid
      @_type = ssid
      @_tag = plugin.tagFromSSID(ssid)
      location = plugin.locationFromTag(@_tag)
      location = plugin.locationFromTag(@_tag)
      @_latitude = location?.gps?.latitude or 0
      @_longitude = location?.gps?.longitude or 0
      return @_emitUpdates("Update location for #{@name}: SSID:#{@_ssid}")

    updateLocation: (long, lat, updateAddress) ->
      # legacy action for pimatic-location android client
      @_setTimeStamp()
      @_source = "LOC"
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0
      @_gps = JSON.stringify({"latitude": @_latitude, "longitude": @_longitude})
      @_tag = plugin.tagFromGPS({"latitude": lat, "longitude": long})
      return @_emitUpdates("Update location for #{@name}: GPS:#{@_latitude},#{@_longitude}")

    _emitUpdates: (logMsg) ->
      env.logger.debug(logMsg)
      for key, value of @.attributes
        @emit key, @['_'+ key] if key isnt '__proto__' and @['_'+ key]?
      return Promise.resolve()

    _clearUpdates: () ->
      for key, value of @.attributes
        @['_'+ key] = null if key isnt '__proto__'

    _setTimeStamp: () ->
      @_clearUpdates()
      @_timeSpec = new Date().format(@timeformat)

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
