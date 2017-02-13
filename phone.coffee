module.exports = (env) =>

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  t = env.require('decl-api').types

  geolib = require 'geolib'
  actions = require('./actions.coffee')(env)
  predicates = require('./predicates.coffee')(env)

  ############################################
  class PhonePlugin extends env.plugins.Plugin
  ############################################

    init: (app, @framework, @config) =>

      @_afterInit = false

      @debug = @config.debug || false
      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass('PhoneDevice', {
        configDef: deviceConfigDef.PhoneDevice,
        createCallback: (config, lastState) =>
          config.iFrame = {} unless config.iFrame?
          return new PhoneDevice(config, lastState, @)
      })

      @framework.deviceManager.registerDeviceClass('PhoneDeviceIOS', {
        configDef: deviceConfigDef.PhoneDeviceIOS,
        createCallback: (config, lastState) =>
          config.iFrame = {} unless config.iFrame?
          return new PhoneDeviceIOS(config, lastState, @)
      })

      @framework.ruleManager.addActionProvider(new actions.SetSuspendActionProvider(@framework))
      #@framework.ruleManager.addPredicateProvider(new predicates.TagPredicateProvider(@framework))

      @framework.on 'after init', =>
        @_afterInit = true

    afterInit: () =>
      return @_afterInit

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


  ############################################
  class PhoneDevice extends env.devices.Device
  ############################################

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
      timeStamp:
        label: "Update time stamp"
        description: "Date and time of the last location update."
        type: t.number
        unit: ""
        acronym: 'UTC'
        displaySparkline: false
        hidden: true
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
      previousTag:
        description: "Previous location of the device"
        type: t.string
        unit: ""
        acronym: 'PREV'
        displaySparkline: false
        hidden: true
        discrete: true
      previousLocation:
        description: "Alias for the previous tag attribute"
        type: t.string
        unit: ""
        acronym: 'PREV'
        displaySparkline: false
        hidden: true
        discrete: true
      previousPosition:
        description: "Alias for the previous tag attribute"
        type: t.string
        unit: ""
        acronym: 'PREV'
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
        description: "Variable update record"
        params:
          record:
            type: t.string
      updatePhone:
        description: "Update from Android Tasker APP"
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
      enter:
        description: "Enter geofence"
        params:
          tag:
            type: t.string
      exit:
        description: "Exit geofence"
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
      fetchLocation:
        description: "Return current device location"
      fetchPreviousLocation:
        description: "Return previous device location"

    # attribute getter methods
    getSource: () -> Promise.resolve(@_source)
    getTag: () -> Promise.resolve(@_tag)
    getLocation: () -> Promise.resolve(@_tag)
    getPosition: () -> Promise.resolve(@_tag)
    getPreviousTag: () -> Promise.resolve(@_last_tag)
    getPreviousLocation: () -> Promise.resolve(@_last_tag)
    getPreviousPosition: () -> Promise.resolve(@_last_tag)
    getTimeSpec: () -> Promise.resolve(@_timeSpec)
    getTimeStamp: () -> Promise.resolve(@_timeStamp)
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
      @deviceManager = plugin.framework.deviceManager
      @variableManager = plugin.framework.variableManager
      @pluginManager = plugin.framework.pluginManager
      @framework = plugin.framework

      @iFrame = null

      # use device specific debug flag
      # to allow changes during runtime
      @_debug = @config.debug || false
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
        if lastState and lastState[attributeName]
          @['_'+attributeName] = lastState[attributeName].value or 0

      # device attribute initialization
      @_serial = @config.serial

      @_tag = lastState?.tag?.value or "unknown"
      @_type = lastState?.type?.value or "?"
      @_source = lastState?.source?.value or "?"
      @_latitude = lastState?.latitude?.value or null
      @_longitude = lastState?.longitude?.value or null
      @_timeStamp = lastState?.timeStamp?.value or new Date().getTime()
      @_timeSpec = lastState?.timeSpec?.value or new Date(@_timeStamp).format(@timeformat)

      super()

      # initialization has to be done after super() !!!
      @_setTimeStamp(false) # initialize @_last_* but don't clear attributes
      @_emitUpdates("Initial location update for device #{@id}", true)

      @framework.on 'after init', =>
        # run once after system init
        @_init()

      if plugin.afterInit()
        # and after recreation: constructor == true and afterInit == false
        @_init()

    iframeHandler = (state) ->
      # this == switch device !!!
      @phone.iFrame.enabled = state
      @phone.config.iFrame.enabled
      @phone.debug("@iFrame[enabled] set to #{@phone.iFrame.enabled}")

    _init: () =>
      @debug("PhoneDevice Initialization")
      iFramePlugin = @pluginManager.getPlugin('iframe')
      if iFramePlugin?
        @debug("Found pimatic-iframe plugin")
        if !!@config.iFrame?.id
          iFrame = @deviceManager.getDeviceById(@config.iFrame.id)
          if iFrame?
            @debug("Using iFrame device #{iFrame.id}")
            # TODO: check instance of plugin device ???
            # if iFrame instanceof iFramePlugin.iframeDevice
            actuator = @deviceManager.getDeviceById(@config.iFrame.switch)
            if actuator? and actuator instanceof env.devices.SwitchActuator
              @debug("Using switch #{actuator.id}")
              actuator.changeStateTo(@config.iFrame.enabled)
              actuator.phone = @
              actuator.on 'state', iframeHandler
            if !!@config.iFrame.url
              @iFrame = {
                device: iFrame
                key: @config.iFrame.key
                url: @config.iFrame.url
                enabled: @config.iFrame.enabled
                switch: actuator
              }
              @iframeUpdate()
            else
              env.logger.error("Missing template URL for #{@config.iFrame.id}")
            # else
            #  env.logger.error("Device #{@config.iFrame?.id} is not an iFrame!")
          else
            env.logger.error("iFrame device #{@config.iFrame.id} not found!")


    debug: (message) =>
      if @debug
        env.logger.debug("Device #{@id}: " + message)

    destroy: () ->
      if @iFrame?.switch?
        @iFrame.switch.removeListener 'state', iframeHandler
      super()

    fetchLocation: () ->
      return Promise.resolve(@_locationResponse())

    fetchPreviousLocation: () ->
      return Promise.resolve(@_locationResponse(true))

    update: (record) ->
      # TODO: process update record
      @_setTimeStamp()
      throw new Error("Not implemented: Ignoring update record [#{record}]")

    enter: (tag) ->
      @_setTimeStamp()
      @_source = "GEO"
      @_tag = tag
      @_type = "API"
      @_updateLocation(@_tag)
      return @_emitUpdates("Update location for \"#{@name}\": geo: [#{@_tag}]")

    exit: (tag) ->
      @_setTimeStamp()
      @_source = "GEO"
      @_tag = "unknown"
      @_type = "API"
      @_updateLocation(@_tag)
      return @_emitUpdates("Update location for \"#{@name}\": geo: [#{@_tag}]")

    updateTag: (tag) ->
      @_setTimeStamp()
      @_source = "TAG"
      @_tag = tag
      @_type = "API"
      @_updateLocation(@_tag)
      return @_emitUpdates("Update location for \"#{@name}\": tag: [#{@_tag}]")

    updatePhone: (serial, ssid, cellid, locn, loc) ->
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
      msg = "Update location for \"#{@name}\": GPS:#{@_latitude},#{@_longitude},#{@_accuracy} \
        Tag: [#{@_tag}]"
      return @_emitUpdates(msg)

    updateLocation: (long, lat, updateAddress) ->
      # legacy action for pimatic-location android client
      @_setTimeStamp()
      @_source = "LOC"
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0
      @_type = "GPS"
      @_tag = plugin.tagFromGPS({"latitude": lat, "longitude": long})
      env.logger.debug("Legacy updateLocation: updateAddress [#{updateAddress}] ignored.")
      return @_emitUpdates("Update location for \"#{@name}\": GPS:#{@_latitude},#{@_longitude}")

    ###
    disableUpdates: () ->
      throw new Error("Call [disableUpdates] only available for iOS devices")
    enableUpdates: (code) ->
      throw new Error("Call [enableUpdates?=#{code}] only available for iOS devices")
    suspend: (flag) ->
      throw new Error("Call [suspend?flag=#{flag}] only available for iOS devices")
    ###

    _gpsFromTaskerLocation: (loc) ->
      gps = {}
      if ! loc.startsWith('%')
        data = loc.split(',',3)
        gps.latitude = parseFloat(data[0])
        gps.longitude = parseFloat(data[1])
        if ! data[2].startsWith('%')
          gps.accuracy = parseInt(data[2])
      return gps

    _processLocation: (force=false) ->
      # process gps location data and calculate distances
      @_gps_previous = _.clone(@_gps_last, true) if @_gps_last?
      @_gps_current = null
      if @_latitude? and @_longitude?
        @debug("Current position: lat=#{@_latitude} long=#{@_longitude}" )
        @_gps_current = {}
        @_gps_current.latitude = @_latitude if @_latitude
        @_gps_current.longitude = @_longitude if @_longitude
        @_gps_current.accuracy = @_accuracy if @_accuracy
        @_gps = JSON.stringify(@_gps_current)

      # calculate distance to the last position
      @_gps_moved = null
      if @_gps_last? and @_gps_current?
        try
          @_gps_moved = geolib.getDistance(@_gps_last, @_gps_current)
          @debug("Distance to last known postition: #{@_gps_moved}m")
        catch error
          env.logger.error(error)
      @_gps_last = _.clone(@_gps_current, true)

      # calculate distance for every location tag
      if @_gps_current?
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
          @debug("Distance to #{location.tag}: #{distance}m")

    _emitUpdates: (logMsg, force=false) ->
      env.logger.debug(logMsg)
      @_processLocation(force)

      # update xLink URL
      if @_latitude? and @_longitude?
        @config.xLink = @config.xLinkTemplate.replace("{latitude}", @_latitude.toString())
          .replace("{longitude}", @_longitude.toString())

      changed = true
      if @_last_source != @_source
        @debug("Source changed #{@_last_source} -> #{@_source}")
      else if @_last_type != @_type
        @debug("Type changed #{@_last_type} -> #{@_type}")
      else if @_last_tag != @_tag
        @debug("Tag changed #{@_last_tag} -> #{@_tag}")
      else if (@_tag == "unknown") and (@_gps_moved > @gpsLimit)
        @debug("GPS moved #{@_gps_moved}")
      else
        @debug("Location not changed.")
        changed = false

      if changed or force
        @debug("Updating device attributes [force=#{force}]")
        for key, value of @.attributes
          # @debug("#{key}=#{@['_'+ key]}") if key isnt '__proto__' and @['_'+ key]?
          @emit key, @['_'+ key] if key isnt '__proto__' and @['_'+ key]?
        @iframeUpdate()

      return Promise.resolve(@_locationResponse())

    _clearUpdates: () =>
      for key, value of @.attributes
        @['_'+ key] = null if key isnt '__proto__'

    _setTimeStamp: (update=true) =>
      # save values from previous update
      @_last_tag = @_tag
      @_last_source = @_source
      @_last_type = @_type
      @_last_timeSpec = @_timeSpec
      @_last_timeStamp = @_timeStamp
      if update
        # fetch update timestamp and clear local vars
        @_clearUpdates()
        @_timeStamp = new Date().getTime()
        @_timeSpec = new Date(@_timeStamp).format(@timeformat)
        #@_timeStamp = new Date()
        #@_timeSpec = @_timeStamp.format(@timeformat)

    _updateLocation: (tag) ->
      # set gps location from tag
      location = plugin.locationFromTag(@_tag)
      @_latitude = location?.gps?.latitude or null
      @_longitude = location?.gps?.longitude or null

    iframeUpdate: () ->
      return unless @iFrame? and @_latitude? and @_longitude?
      return unless @iFrame.enabled
      url = @iFrame.url
        .replace("{key}", @iFrame.key)
        .replace("{latitude}", @_latitude.toString())
        .replace("{longitude}", @_longitude.toString())
      @debug("Reload iFrame with #{url}")
      @iFrame.device.loadIFrameWith(url)

    _locationResponse: (previous=false) =>
      response = {}
      if previous
        response.tag = @_last_tag if @_last_tag?
        response.source = @_last_source if @_last_source?
        response.type = @_last_type if @_last_type?
        response.time = @_last_timeSpec if @_last_timeSpec
        response.utc = @_last_timeStamp if @_last_timeStamp
        response.gps = _.clone(@_gps_previous, true) if @_gps_previous?
      else
        response.tag = @_tag if @_tag?
        response.source = @_source if @_source?
        response.type = @_type if @_type?
        response.time = @_timeSpec if @_timeSpec
        response.utc = @_timeStamp if @_timeStamp
        response.gps = _.clone(@_gps_current, true) if @_gps_current?
      return response


  ########################################
  class PhoneDeviceIOS extends PhoneDevice
  ########################################

    # require 'coffee-script/register'
    icloud = require 'icloud-promise'

    getSuspended: () -> Promise.resolve(@_suspended)

    constructor: (@config, lastState, plugin) ->

      # extend PhoneDevice attributes
      @attributes = _.clone(@attributes)
      @attributes['suspended'] = {
        label: "Suspended"
        description: "iCloud updates suspended"
        type: t.boolean
        acronym: 'OFF'
        displaySparkline: false
        hidden: true
      }

      # extend PhoneDevice actions
      @actions = _.clone(@actions)
      @actions['suspend'] = {
        description: "Suspend iCloud location updates"
        params:
          flag:
            type: t.string
      }
      @actions['disableUpdates'] = {
        description: "Disable iCloud location updates"
      }
      @actions['enableUpdates'] = {
        description: "Enable iCloud location updates"
        params:
          code:
            description: "iCloud 2FA verification code code"
            type: t.string
      }

      @_suspended = laststate?.suspended?.value or true

      super(@config, lastState, plugin)

      @iCloudUser = @config.iCloudUser
      @iCloudPass = @config.iCloudPass
      @iCloudDevice = @config.iCloudDevice
      @iCloudInterval = @config.iCloudInterval
      @iCloudVerify = @config.iCloudVerify
      @iCloudTimezone = @config.iCloudTimezone
      @iCloudSessionTimeout = @config.iCloudSessionTimeout

      # @_suspended = @config.iCloudSuspended
      @_suspendState(@config.iCloudSuspended)
      
      @iCloudClient = null

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
                          @_refreshWebAuth()
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

    _init: () =>
      @debug("PhoneDeviceIOS initialization")
      @iCloudSwitch = @deviceManager.getDeviceById(@config.iCloudSwitch)
      if @iCloudSwitch? and @iCloudSwitch instanceof env.devices.SwitchActuator
        @debug("Using switch #{@iCloudSwitch.id}")
        # @iCloudSwitch.changeStateTo(! @_suspended)
        @iCloudSwitch.phone = @
        @iCloudSwitch.on 'state', suspendHandler

      super()

    destroy: () ->
      clearInterval @intervalId if @intervalId?
      clearInterval @refreshClientId if @refreshClientId?
      if @iCloudClient?
        @iCloudClient.logout()
        .then( () ->
          env.logger.debug("iCloud session logout")
        )
        .catch( (error) ->
          env.logger.debug("iCloud session logout failed: " + error.message)
        )
        if @iCloudSwitch?
          @iCloudSwitch.removeListener 'state', suspendHandler

      super()

    disableUpdates: () =>
      if not @iCloudClient.hsaChallengeRequired
        env.logger.warn("Use suspend?flag=false call for 2FA disabled accounts!")
      if @iCloudClient.authenticated
        @iCloudClient.logout()
        .then( () =>
          env.logger.info("Logout from #{@iCloudDevice} succeeded")
          @_suspendState(true)
          return Promise.resolve("iCloud location updates for #{@iCloudDevice} disabled!")
        )
        .catch( (error) =>
          return Promise.reject(new Error("Logout failed for #{@iCloudDevice}, " + error.message))
        )
      else
        @_suspendState(true)
        return Promise.resolve("iCloud location updates for #{@iCloudDevice} disabled!")

    enableUpdates: (code) =>
      @iCloudVerify = code
      @iCloudClient.verify = code
      if not @iCloudClient.hsaChallengeRequired
        env.logger.warn("Use suspend?flag=true call for 2FA disabled accounts!")
      if @iCloudClient.authenticated
        msg = "Found active session for \"#{@iCloudDevice}\". Use disableUpdates first!"
        throw new Error(msg)
      else
        @iCloudClient.login()
        .then(() =>
          @_refreshClient()
          .then(() =>
            @_suspendState(false)
            return Promise.resolve("iCloud location updates for #{@iCloudDevice} enabled")
          )
        )
        .catch( (error) ->
          return Promise.reject(error)
        )

    suspend: (flag) =>
      if @iCloudClient.hsaChallengeRequired
        env.logger.warn("Use disable/enableUpdates call for 2FA enabled accounts!")
      @_suspendState(flag.toUpperCase() in ['ON','AN','TRUE','JA','YES','1','EIN'])
      # throw new Error("Error!")
      return Promise.resolve(@_suspended)

    suspendHandler = (state) ->
      # this == switch device !!!
      @phone._suspendState(!state, true)
      #@phone.iCloudSuspended = !state
      #@phone.config.iCloudSuspended = @iCloudSuspended
      #@phone.debug("@iCloudSuspended set to #{@phone.iCloudSuspended}")

    _suspendState: (flag, handler = false) =>
      return unless @_suspended isnt flag
      @_suspended = flag
      @emit @suspended, @_suspended
      # @config.iCloudSuspended = flag
      if @iCloudSwitch?
        @iCloudSwitch.changeStateTo(!@_suspended) unless handler
      state = if @_suspended then 'disabled' else 'enabled'
      env.logger.info("Location updates for \"#{@iCloudDevice}\": [#{state}]")
      return Promise.resolve(@_suspended)

    _refreshWebAuth: () =>
      @iCloudClient.refreshWebAuth()
      .then(() ->
        env.logger.debug("iCloud session refresh for \"#{@iCloudDevice}\" succeeded")
      )
      .catch( (error) ->
        env.logger.error("iCloud session refresh for \"#{@iCloudDevice}\" failed: " + error.message)
      )

    _refreshClient: () =>
      @iCloudClient.refreshClient()
      .then((response) =>
        found = _.find(@iCloudClient.devices, name: @iCloudDevice)
        if found
          if found.location?
            location = found.location
            @updateGPS(location.latitude, location.longitude, \
              location.horizontalAccuracy, location.positionType)
            msg = "Location of device \"#{@iCloudDevice}\" updated"
            env.logger.debug(msg)
            return Promise.resolve(response)
          else
            msg = "No location information available for device \"#{@iCloudDevice}\"!"
            throw new Error(msg)
        else
          devs = @iCloudClient.deviceNames().join(', ')
          msg = "iCloud device \"#{@iCloudDevice}\" not found in [#{devs}]!"
          throw new Error(msg)
      )
      .catch( (error) =>
        env.logger.error("Update of device \"#{@iCloudDevice}\" failed, " + error.message)
        return Promise.reject(error)
      )

    _updateDevice: () =>
      if @_suspended
        env.logger.debug("Location update for \"#{@iCloudDevice}\" suspended. \
          Skipping refresh call ...")
      else
        @_refreshClient().catch(() -> return false)
        return true

  return plugin
