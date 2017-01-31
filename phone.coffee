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
      result = {distance: null, tag: 'unknown'}
      if position?
        for location in @config.locations
          if location.gps?
            gps = location.gps
            radius = if accuracy > 0 then accuracy else gps.radius
            try
              if geolib.isPointInCircle(position, gps, radius)
                distance = geolib.getDistance(position, gps)
                if result.distance == null or result.distance > distance
                  result = {distance: distance, tag: location.tag}
            catch error
              env.logger.error(error.message)
      return result.tag

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
      location:
        description: "Alias for the tag attribute"
        type: t.string
        unit: ""
        acronym: 'LOC'
        displaySparkline: false
        hidden: true
        discrete: true
      position:
        description: "Alias for the tag attribute"
        type: t.string
        unit: ""
        acronym: 'LOC'
        displaySparkline: false
        hidden: true
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
      updatePhone:
        decription: "Update from Android Tasker APP"
        params:
          serial:
            type: t.string
          ssid:
            type: t.string
          cellid:
            type: t.string
          locn:
            type: t.string
          loc:
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
    getLocation: () -> Promise.resolve(@_location)
    getPosition: () -> Promise.resolve(@_position)
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
      @gpsLimit = @config.gpsLimit

      # create distance attributes for every location
      for location in plugin.config.locations
        attributeName = "distanceTo" + location.tag
        @addAttribute(attributeName, {
          description: "Distance between #{@name} and #{location.tag}"
          type: t.number
          unit: "m"
          acronym: 'DTL'
          hidden: location.tag != plugin.config.homelocation
        })
        @['_'+attributeName] = null
        @['getDistanceTo'+location.tag] = ()-> Promise.resolve(@["_"+attributeName])

      # device attribute initialization
      @_serial = @config.serial

      @_tag = lastState?.tag?.value or "unknown"
      @_type = lastState?.type?.value or "?"
      @_source = lastState?.source?.value or "?"

      @_last_tag = @_tag
      @_last_type = @_type
      @_last_source = @_source

      @_location = @_tag
      @_position = @_tag

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
      @_updateLocation(@_tag)
      return @_emitUpdates("Update location for \"#{@name}\": TAG:#{@_tag}")

    updatePhone: (serial, ssid, cellid, locn, loc) ->
      @_setTimeStamp()
      tag = null
      if ! ssid.startsWith('%')
        tag = plugin.tagFromSSID(ssid)
        if tag != "unknown"
          return @updateSSID(ssid)
      # not connected to WLAN, use GPS or NET location
      gps = null
      type = null
      if ! loc.startsWith('%')
        gps = @_gpsFromTaskerLocation(loc)
        type = 'GPS'
      else if ! locn.startsWith('%')
        gps = @_gpsFromTaskerLocation(locn)
        type = 'NET'
      else if ! cellid.startsWith('%')
        return @updateCID(cellid)
      if gps?
        return @updateGPS(gps.latitude, gps.longitude, gps.accuracy, type)

    updateCID: (cell) ->
      @_setTimeStamp()
      @_source = "CID"
      @_cell = cell
      @_type = "CID"
      @_tag = plugin.tagFromCID(cell)
      @_updateLocation(@_tag)
      return @_emitUpdates("Update location for \"#{@name}V: #{@_cell}")

    updateSSID: (ssid) ->
      @_setTimeStamp()
      @_source = "SSID"
      @_ssid = ssid
      @_type = ssid
      @_tag = plugin.tagFromSSID(ssid)
      @_updateLocation(@_tag)
      return @_emitUpdates("Update location for \"#{@name}\": SSID:#{@_ssid}")

    updateGPS: (latitude, longitude, accuracy, type) ->
      @_setTimeStamp()
      @_source = "GPS"
      @_latitude = latitude
      @_longitude = longitude
      @_accuracy = accuracy
      @_type = type
      @_tag = plugin.tagFromGPS({"latitude": latitude, "longitude": longitude}, @accuracy)
      msg = "Update location for \"#{@name}\": GPS:#{@_latitude},#{@_longitude},#{@_accuracy}"
      return @_emitUpdates(msg)

    updateLocation: (long, lat, updateAddress) ->
      # legacy action for pimatic-location android client
      not_used = updateAddress
      @_setTimeStamp()
      @_source = "LOC"
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0
      @_type = "GPS"
      @_tag = plugin.tagFromGPS({"latitude": lat, "longitude": long})
      return @_emitUpdates("Update location for \"#{@name}\": GPS:#{@_latitude},#{@_longitude}")

    _gpsFromTaskerLocation: (loc) ->
      gps = {}
      if ! loc.startsWith('%')
        data = loc.split(',',3)
        gps.latitude = parseFloat(data[0])
        gps.longitude = parseFloat(data[1])
        if ! data[2].startsWith('%')
          gps.accuracy = parseInt(data[2])
      return gps

    _processLocation: () ->
      # process gps location data and calculate distances
      @_gps_current = {}
      @_gps_current.latitude = @_latitude if @_latitude
      @_gps_current.longitude = @_longitude if @_longitude
      @_gps_current.accuracy = @_accuracy if @_accuracy
      @_gps = JSON.stringify(@_gps_current)

      # calculate distance to the last position
      @_gps_moved = null
      if @_gps_last?
        try
          @_gps_moved = geolib.getDistance(@_gps_last, @_gps_current)
        catch error
          env.logger.error(error)
      @_gps_last = _.clone(@_gps_current, true)

      # calculate distance for every location tag
      for location in plugin.config.locations
        attributeName = "_distanceTo" + location.tag
        distance = null
        if location.tag == @_tag
          distance = 0
        else
          if location.gps?
            try
              distance = geolib.getDistance(@_gps_current, location.gps)
            catch error
              env.logger.error(error)

        # update distance attribute for this location
        @[attributeName] = distance

    _emitUpdates: (logMsg) ->
      env.logger.debug(logMsg)
      @_processLocation()

      # update tag aliases
      @_location = @_tag
      @_position = @_tag

      # update xLink URL
      if @_latitude? and @_longitude?
        @config.xLink = @config.xLinkTemplate.replace("{latitude}", @_latitude.toString())
          .replace("{longitude}", @_longitude.toString())

      # emit only if tag has changed or we are significantly moving outside a known position
      if (@_last_source != @_source) \
      or (@_last_type != @_type) \
      or (@_last_tag != @_tag) \
      or (@_tag == "unknown" and (@_gps_moved > @gpsLimit))
        for key, value of @.attributes
          @emit key, @['_'+ key] if key isnt '__proto__' and @['_'+ key]?

      @_last_tag = @_tag
      @_last_source = @_source
      @_last_type = @_type
      return Promise.resolve()

    _clearUpdates: () ->
      for key, value of @.attributes
        @['_'+ key] = null if key isnt '__proto__'

    _setTimeStamp: () ->
      # fetch update timestamp and clear local vars
      @_clearUpdates()
      @_timeSpec = new Date().format(@timeformat)

    _updateLocation: (tag) ->
      # set gps location from tag
      location = plugin.locationFromTag(@_tag)
      @_latitude = location?.gps?.latitude or null
      @_longitude = location?.gps?.longitude or null


  class PhoneDeviceIOS extends PhoneDevice

    require 'coffee-script/register'
    icloud = require 'icloud-promise'

    actions:
      suspend:
        decription: "Suspend iCloud location updates"
        params:
          flag:
            type: t.string

    constructor: (@config, lastState, plugin) ->

      super(@config, lastState, plugin)

      @iCloudUser = @config.iCloudUser
      @iCloudPass = @config.iCloudPass
      @iCloudDevice = @config.iCloudDevice
      @iCloudInterval = @config.iCloudInterval
      @iCloudVerify = @config.iCloudVerify
      @iCloudTimezone = @config.iCloudTimezone
      @iCloudSessionTimeout = @config.iCloudSessionTimeout
      @iCloudClient = null
      @iCloudSuspend = false

      @config.iCloudVerify = '000000'

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
              @iCloudClient = new icloud.ICloudClient(
                @iCloudUser, @iCloudPass, @iCloudVerify, @iCloudTimezone)
              @iCloudClient.login()
              .then( () =>
                if @iCloudClient.hsaChallengeRequired
                  env.logger.warn("Detected 2FA for \"#{@iCloudUser}\". \
                    Some limitations may apply, see documentation for details!")
                  if @iCloudVerify  is '000000'
                    env.logger.warn("You shoud use iCloudVerify attribute \
                      to enter the 2FA verification code!")
                  if @iCloudInterval > @iCloudSessionTimeout * 1000
                    env.logger.warn("Update interval should be less \
                      then 600 seconds due to API issues for 2FA!")
                @iCloudClient.refreshClient()
                .then( () =>
                  found = _.find(@iCloudClient.devices, name: @iCloudDevice)
                  if found
                    env.logger.info("Found device \"#{@iCloudDevice}\" for #{@iCloudUser}")
                    if found.location?
                      env.logger.info("Location information available \
                        for device \"#{@iCloudDevice}\"")
                      location = found.location
                      @updateGPS(location.latitude, location.longitude, \
                        location.horizontalAccuracy, location.positionType)
                      @intervalId = setInterval(( =>
                        @_updateDevice()
                      ), @iCloudInterval * 1000)
                      if @iCloudInterval > @iCloudSessionTimeout
                        @refreshClientId = setInterval(( =>
                          @_refreshClient()
                        ), (@iCloudSessionTimeout - 5) * 1000)
                        env.logger.info("iCloud session heartbeat initialized")
                    else
                      env.logger.error("No location information available \
                        for device \"#{@iCloudDevice}\"!")
                  else
                    devs = @iCloudClient.deviceNames().join(', ')
                    env.logger.error("iCloud device \"#{@iCloudDevice}\" not found in [#{devs}]!")
                )
                .catch( (error) =>
                  env.logger.error("Device update of \"#{@iCloudDevice}\" failed, " + error.message)
                )
              )
              .catch( (error) =>
                env.logger.error("Login failed for \"#{@iCloudUser}\", " + error.message)
              )

    destroy: () ->
      clearInterval @intervalId if @intervalId?
      clearInterval @refreshClientId if @refreshClientId?
      if @iCloudClient?
        @iCloudClient.logout()
        .then( (response) ->
          env.logger.debug("iCloud session logout")
        )
        .catch( (error) ->
          env.logger.debug("iCloud session logout failed: " + error.message)
        )
      super()

    suspend: (flag) =>
      if flag.toUpperCase() in ['ON','AN','TRUE','JA','YES','1','EIN']
        @iCloudSuspend = true
        env.logger.info("Location updates for #{@iCloudDevice} suspended!")
        return true
      else
        @iCloudSuspend = false
        env.logger.info("Location updates for #{@iCloudDevice} enabled!")
        return false

    _refreshClient: () =>
      @iCloudClient.refreshWebAuth()
      .then( (response) ->
        env.logger.debug("iCloud session refresh succeeded")
      )
      .catch( (error) ->
        env.logger.error("iCloud session refresh failed: " + error.message)
      )

    _updateDevice: () =>
      if @iCloudSuspend
        env.logger.debug("Location update for \"#{@iCloudDevice}\" skipped.")
        return
      @iCloudClient.refreshClient()
      .then((response) =>
        found = _.find(@iCloudClient.devices, name: @iCloudDevice)
        if found
          if found.location?
            location = found.location
            @updateGPS(location.latitude, location.longitude, \
              location.horizontalAccuracy, location.positionType)
          else
            env.logger.debug("No location information available for device \"#{@iCloudDevice}\"!")
        else
          devs = @iCloudClient.deviceNames().join(', ')
          env.logger.error("iCloud device \"#{@iCloudDevice}\" not found in [#{devs}]!")
      )
      .catch( (error) =>
        env.logger.error("Update of device \"#{@iCloudDevice}\" failed, " + error.message)
       )

  return plugin
