module.exports = (env) =>

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  t = env.require('decl-api').types

  geolib = require 'geolib'
  googlemaps = require '@google/maps'
  actions = require('./actions.coffee')(env)

  ############################################
  class PhonePlugin extends env.plugins.Plugin
  ############################################
  
    preConfig: (config) ->
      config.iFrame = {} unless config.iFrame?
      config.googleMaps = {} unless config.googleMaps?
      if config.iFrame.key?
        config["googleMaps"]["key"] = config.iFrame.key
        delete(config.iFrame["key"])
      return config
      
    postConfig: (device) ->
      if not device.config.xAttributeOptions?
        device.config.xAttributeOptions = []
      xAttr = device.config.xAttributeOptions
      for attr in ['timeSpec', 'tag', 'source', 'type', 'latitude', 'longitude', 'address']
        if not _.find(xAttr, name: attr)
          xattr = {name: attr}
          for entry in ['displaySparkline', 'hidden']
            if device.attributes[attr][entry]? and device.attributes[attr][entry]
              xattr[entry] = device.attributes[attr][entry]
          xAttr.push(xattr)
      return device

    init: (app, @framework, @config) =>

      for location in @locations()
        location["address"] = "" unless location.address?
        location["data"] = {} unless location.data?

      @_afterInit = false

      @debug = @config.debug || false
      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass('PhoneDevice', {
        configDef: deviceConfigDef.PhoneDevice,
        createCallback: (config, lastState) =>
          config = @preConfig(config)
          return @postConfig new PhoneDevice(config, lastState, @)
      })

      @framework.deviceManager.registerDeviceClass('PhoneDeviceIOS', {
        configDef: deviceConfigDef.PhoneDeviceIOS,
        createCallback: (config, lastState) =>
          config = @preConfig(config)
          return @postConfig new PhoneDeviceIOS(config, lastState, @)
      })

      @framework.ruleManager.addActionProvider(new actions.SetSuspendActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new actions.SetLocationActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new actions.SetAddressActionProvider(@framework))

      @framework.on 'after init', =>
        @_afterInit = true

    afterInit: () =>
      return @_afterInit
      
    locations: () =>
      return _.find(@framework.config.plugins, 'plugin': 'phone')?.locations or []

    tagFromGPS: (position, accuracy) =>
      result = {distance: null, tag: 'unknown'}
      if position?
        for location in @locations()
          if location.gps? and location.gps.radius?
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
        for location in @locations()
          if location.ssids?
            if location.ssids.indexOf(ssid) > -1
              return location.tag
      return "unknown"

    tagFromCID: (cid) =>
      if cid?
        for location in @locations()
          if location.cids?
            if location.cids.indexOf(cid) > -1
              return location.tag
      return "unknown"

    isValidTag: (tag) =>
      if tag?
        return _.find(@locations(), 'tag': tag)?
      return false

    locationFromTag: (tag) =>
      if tag?
        return _.find(@locations(), 'tag': tag)
      return null

    getTags: () =>
      # tags = []
      # _.forEach @locations(), (location) ->
      #  tags.push location.tag
      return _.map @locations(), 'tag'


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
      source:
        label: "Location source"
        description: "Source of location information: LOC, GPS, NET, TAG, SSID, ..."
        type: t.string
        unit: ""
        acronym: 'SRC'
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
      address:
        label: "Address"
        description: "Address of device"
        type: t.string
        unit: ""
        acronym: 'ADDR'
        displaySparkline: false
        hidden: false

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
      updateAddress:
        description: "Update address of device"
        params:
          address:
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
      updatePluginConfig:
        description: "Update location settings via geocoding lookups"

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
    getAddress: () -> Promise.resolve(@_address)

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
      @googleMapsClient = null

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
          displaySparkline: false
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
      @_address = lastState?.address?.value or null
      @_timeStamp = lastState?.timeStamp?.value or new Date().getTime()
      @_timeSpec = lastState?.timeSpec?.value or new Date(@_timeStamp).format(@timeformat)

      super()

      # initialization has to be done after super() !!!
      @_setTimeStamp(false) # initialize @_last_* but don't clear attributes
      @_emitUpdates("constructor", true)

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
      @phone._updateAddress() if state
      @phone.debug("@iFrame[enabled] set to #{@phone.iFrame.enabled}")

    _init: () =>
      @debug("PhoneDevice Initialization")
      if !! @config.googleMaps.key
        @googleMapsClient = googlemaps.createClient({key: @config.googleMaps.key, Promise: Promise})
        @debug("Using googleMapsClient with key=#{@config.googleMaps.key}")
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
                url: @config.iFrame.url
                enabled: @config.iFrame.enabled
                switch: actuator
              }
              @_updateAddress()
            else
              env.logger.error("Missing template URL for #{@config.iFrame.id}")
            # else
            #  env.logger.error("Device #{@config.iFrame?.id} is not an iFrame!")
          else
            env.logger.error("iFrame device #{@config.iFrame.id} not found!")

    debug: (message) =>
      if @debug
        env.logger.debug("Device #{@config.id}: " + message)

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
      @debug("enter tag=#{tag}")
      @_setTimeStamp()
      @_source = "GEO"
      @_tag = tag
      @_type = "API"
      return @_emitUpdates("enter")

    exit: (tag) ->
      @debug("exit tag=#{tag}")
      @_setTimeStamp()
      @_source = "GEO"
      @_tag = "unknown"
      @_type = "API"
      return @_emitUpdates("exit")

    updateTag: (tag) ->
      @debug("updateTag tag=#{tag}")
      @_setTimeStamp()
      @_source = "TAG"
      @_tag = tag
      @_type = "API"
      return @_emitUpdates("updateTag")

    updatePluginConfig: () ->
      @debug("updatePluginConfig")
      enabled = @googleMapsClient? and
        @config.googleMaps?.geocoding and
        @config.googleMaps?.reverseGeocoding
      if not enabled
        return Promise.reject("Google Maps Geocoding not enabled!")
      lookupLocations = []
      lookupPromises = []
      for location in plugin.locations()
        tag = location.tag
        gps = location.gps? and location.gps.radius?
        addr = !!location.address
        if !gps and addr
          @debug("No GPS found for [#{tag}], using [#{location.address}] for geocoding lookup")
          lookupLocations.push(location)
          lookupPromises.push(@_geocode({address: location.address}))
        else if !addr and gps
          if location.gps.latitude? and location.gps.longitude?
            lookup = "#{location.gps.latitude},#{location.gps.longitude}"
            @debug("No address found for [#{tag}], using #{lookup} for reverseGeocoding lookup")
            lookupLocations.push(location)
            lookupPromises.push(@_geocode({latlng: lookup}))
        else if !addr and !gps
          @debug("Cannot update [#{location.tag}]: GPS or address required!")
        else
          GPS="#{location.gps.latitude},#{location.gps.longitude}"
          ADDR="#{location.address}"
          @debug("#{location.tag}: #{GPS} #{ADDR}")

      Promise.all(lookupPromises)
      .then( (allResults) =>
        for results, index in allResults
          location = lookupLocations[index]
          if !!location.address
            location.gps.latitude  = results[0].geometry?.location?.lat
            location.gps.longitude = results[0].geometry?.location?.lng
            location.gps.radius = 250
            lookup = "#{location.gps.latitude},#{location.gps.longitude}"
            @debug("Update [#{location.tag}] with #{lookup} from lookup")
          else
            location.address = results[0].formatted_address
            @debug("Updated #{location.tag} with #{location.address}")
        @framework.saveConfig()
        return Promise.resolve(true)
      )
      .catch( (err) => return Promise.reject(false))


    updateAddress: (address) ->
      @debug("updateAddress address=#{address}")
      @_setTimeStamp()
      @_source = "ADDR"
      @_type = "API"
      location = plugin.locationFromTag(address)
      @_tag = "unknown"
      if location?
        @_tag = location.tag
        if location.gps?
          gps = location.gps
          if gps.latitude and gps.longitude
            @debug("updateAddress - found matching tag and gps for address [#{address}]")
            return @_emitUpdates("updateAddress")

      @debug("updateAddress - no location found for address [#{address}]")
      if @googleMapsClient? and @config.googleMaps?.geocoding
        @_geocode({address: address})
        .then( (results) =>

          @_address = results[0].formatted_address
          @_latitude = results[0].geometry?.location?.lat
          @_longitude = results[0].geometry?.location?.lng
          @_tag = plugin.tagFromGPS({latitude: @_latitude, longitude: @_longitude})

          @debug("updateAddress - found [#{@_address}] by geocoding lookup")
          return @_emitUpdates("updateAddress")
        )
        .catch((err) -> return )
      else
        env.logger.error("Geocoding disabled. Cannot lookup address [#{@_address}]")
      return Promise.resolve()

    updatePhone: (serial, ssid, cellid, locn, loc) ->
      @debug("updatePhone: serial=#{serial} ssid=#{ssid} cellid=#{cellid} locn=#{locn} loc=#{loc}")
      tag = null
      if ! ssid.startsWith('%')
        @debug("updatePhone: checking %SSID [#{ssid}]")
        tag = plugin.tagFromSSID(ssid)
        if tag != "unknown"
          return @updateSSID(ssid)
      # not connected to WLAN, use GPS or NET location
      @debug("updatePhone: continue with unknown ssid")
      gps = null
      type = null
      if ! loc.startsWith('%')
        @debug("updatePhone: using GPS from %LOC [#{loc}]")
        gps = @_gpsFromTaskerLocation(loc)
        type = 'GPS'
      else if ! locn.startsWith('%')
        @debug("updatePhone: using GPS from %LOCN [#{locn}]")
        gps = @_gpsFromTaskerLocation(locn)
        type = 'NET'
      else if ! cellid.startsWith('%')
        @debug("updatePhone: using %CELLID [#{cellid}]")
        return @updateCID(cellid)
      if gps?
        return @updateGPS(gps.latitude, gps.longitude, gps.accuracy, type)

    updateCID: (cell) ->
      @debug("updateCID: cell=#{cell}")
      @_setTimeStamp()
      @_source = "CID"
      @_cell = cell
      @_type = "CID"
      @_tag = plugin.tagFromCID(cell)
      @debug("updateCID: #{cell} -> #{@_tag}")
      return @_emitUpdates("updateCID", "")

    updateSSID: (ssid) ->
      @debug("updateSSID: ssid=#{ssid}")
      @_setTimeStamp()
      @_source = "SSID"
      @_ssid = ssid
      @_type = ssid
      @_tag = plugin.tagFromSSID(ssid)
      @debug("updateSSID: #{ssid} -> #{@_tag}")
      return @_emitUpdates("updateSSID")

    updateGPS: (latitude, longitude, accuracy, type) ->
      parms = "latitude=#{latitude} longitude=#{longitude} accuracy=#{accuracy} type=#{type}"
      @debug("updateGPS: #{parms}")
      @_setTimeStamp()
      @_source = "GPS"
      @_latitude = latitude
      @_longitude = longitude
      @_accuracy = accuracy
      @_type = type
      @_tag = plugin.tagFromGPS({"latitude": latitude, "longitude": longitude}, @accuracy)
      @debug("updateGPS: #{latitude},#{longitude} -> #{@_tag}")
      # msg = "GPS:#{@_latitude},#{@_longitude},#{@_accuracy} Tag: [#{@_tag}]"
      return @_emitUpdates("updateGPS")

    updateLocation: (long, lat, updateAddress) ->
      # legacy action for pimatic-location android client
      @debug("updateLocation: long=#{long} lat=#{lat} updateAddress=#{updateAddress}")
      @_setTimeStamp()
      @_source = "LOC"
      @_latitude = lat
      @_longitude = long
      @_accuracy = 0
      @_type = "GPS"
      @_tag = plugin.tagFromGPS({"latitude": lat, "longitude": long})
      @debug("updateLocation: #{lat},#{long} -> #{@_tag}")
      env.logger.debug("Legacy updateLocation: updateAddress [#{updateAddress}] ignored.")
      return @_emitUpdates("updateLocation")

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
        for location in plugin.locations()
          attributeName = "_distanceTo" + location.tag
          distance = null
          if location.tag == @_tag
            distance = 0
          else
            if location.gps? and location.gps.latitude?
              try
                distance = geolib.getDistance(@_gps_current, location.gps)
              catch error
                env.logger.error(error)
            else
              distance = null

          # update distance attribute for this location
          @[attributeName] = distance
          dMsg = if distance? then distance + 'm' else 'unknown!'
          @debug("Distance to #{location.tag}: #{dMsg}")

    _emitUpdates: (caller, force=false) ->
      env.logger.debug("Device #{@config.id}: Update requested by [#{caller}]")

      # set gps location from current tag
      location = plugin.locationFromTag(@_tag)
      if location?
        assert(@_tag == location.tag)
        @_latitude = location.gps?.latitude or null
        @_longitude = location.gps?.longitude or null
      else
        assert(@_tag == "unknown")
        if !!@_latitude or !!@_longitude
          @debug("[No location information available!]")

      @_processLocation(force)  # process GPS coordinates

      # update xLink URL
      if !!@config.xLink and @_latitude? and @_longitude?
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
        @_updateAddress()
        .then( (address) =>
          @debug("Updating device attributes [force=#{force}]")
          for key, value of @.attributes
            @debug("* #{key}=#{@['_'+ key]}") if key isnt '__proto__' and @['_'+ key]?
            @emit key, @['_'+ key] if key isnt '__proto__' and @['_'+ key]?
          return Promise.resolve(@_locationResponse())
        )
        .catch( (err) => return Promise.reject(err) )

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

    _geocode: (input) =>
      return unless @googleMapsClient?
      mode = if input.latlng? then 'reverseGeocode' else 'geocode'
      @googleMapsClient[mode](input).asPromise()
      .then( (response) ->
        if response?.json?.status?
          if response.json.status == 'OK'
            if response.json.results?
              if response.json.results.length > 0
                if mode == 'reverseGeocode'
                  result = response.json.results[0].formatted_address
                else
                  location = response.json.results[0].geometry.location
                  result = "#{location.lat},#{location.lng}"
                env.logger.info("Google Maps #{mode} API returned [#{result}]")
                return Promise.resolve(response.json.results)
            throw new Error("Google Maps #{mode} API returned no results for #{input}")
          else
            status = "[#{response.json.status}]: #{response.json.error_message}"
            throw new Error("Google Maps #{mode} API returned status #{status}")
        else
          throw new Error("Google Maps #{mode} API returned unknown response #{response}")
      )
      .catch( (err) =>
        env.logger.error("#{err}")
        env.logger.error("Google Maps API disabled.")
        @googleMapsClient = null
        return Promise.reject(err)
      )

    _updateAddress: () ->

      ### previous address from geocoding => @_address ###
      if @_source == "ADDR" and !!@_address
        @debug("Keep geocoded address [#{@_address}]")
        @iframeUpdate()
        return Promise.resolve(@_address)

      @_address = "unknown"
      location = plugin.locationFromTag(@_tag)
      
      ### cached valued from location => @_address ###
      if location?
        if !!location.address
          @debug("Using cached address [#{location.address}] for [#{@_tag}]")
          @_address = location.address
          @iframeUpdate()
          return Promise.resolve(@_address)
        else
          @debug("Lookup address for [#{@_tag}]")
      else
        @debug("Lookup address for unknown location")

      ### reverse geocoding with lat/lng => @_address ###
      if !!@_latitude and !!@_longitude
        lookup = "#{@_latitude},#{@_longitude}"
        if @googleMapsClient? and @config.googleMaps?.reverseGeocoding
          @_geocode({latlng: lookup})
          .then( (results) =>
            @_address = results[0].formatted_address
            @emit 'address', @_address
            @iframeUpdate()
            if location?
              location.address = @_address
            return Promise.resolve(@_address)
          )
          .catch((err) -> return Promise.reject(err))

      ### return with @_address == "unknown" ###
      return Promise.resolve(@_address)

    iframeUpdate: () =>
      return unless @iFrame?.enabled
      address = @_address
      latitude = 0
      longitude = 0
      if not address? or address == "" or address == "unknown"
        if !!@_latitude and !!@_longitude
          latitude = @_latitude.toString()
          longitude = @_longitude.toString()
          address = "#{latitude} #{longitude}"
      url = @iFrame.url
        .replace("{key}", @config.googleMaps.key)
        .replace("{latitude}", latitude)
        .replace("{longitude}", longitude)
        .replace("{address}", encodeURIComponent(address))
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

    getSuspended: () -> Promise.resolve(@iCloudSuspended)

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

      super(@config, lastState, plugin)

      @iCloudUser = @config.iCloudUser
      @iCloudPass = @config.iCloudPass
      @iCloudDevice = @config.iCloudDevice
      @iCloudInterval = @config.iCloudInterval
      @iCloudVerify = @_checkVerificationCode(@config.iCloudVerify)
      @iCloudVerifyVariable = @config.iCloudVerifyVariable
      @iCloud2FA = @config.iCloud2FA
      @iCloudTimezone = @config.iCloudTimezone
      @iCloudSessionTimeout = @config.iCloudSessionTimeout
      @iCloudSuspended = @config.iCloudSuspended
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
                @iCloud2FA = @iCloudClient.hsaChallengeRequired
                @config.iCloud2FA = @iCloudClient.hsaChallengeRequired
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

    suspendHandler = (state) ->
      # this == switch device !!!
      @phone.iCloudSuspended = !state
      @phone.config.iCloudSuspended = @phone.iCloudSuspended
      # config attribute in edit dialog not updated
      # @phone.framework.saveConfig()
      @phone.emit 'suspended', @phone.iCloudSuspended
      @phone.debug("iCloudSuspended set to #{@phone.iCloudSuspended}")

    _checkVerificationCode: (code) ->
      if !!code and code.match(/\d{6}/)
        return code
      return '000000'

    _init: () =>
      @debug("PhoneDeviceIOS initialization")
      @iCloudSwitch = @deviceManager.getDeviceById(@config.iCloudSwitch)
      if @iCloudSwitch? and @iCloudSwitch instanceof env.devices.SwitchActuator
        @debug("Using switch #{@iCloudSwitch.id}")
        @iCloudSwitch.changeStateTo(! @config.iCloudSuspended)
        @iCloudSwitch.removeListener 'state', suspendHandler
        @iCloudSwitch.phone = @
        @iCloudSwitch.on 'state', suspendHandler

      super()
      @iCloudSuspended = @config.iCloudSuspended
      state = if @iCloudSuspended then 'disabled' else 'enabled'
      env.logger.info("iCloud location updates for \"#{@config.iCloudDevice}\" #{state}")

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
      if code.startsWith('$')
        code = @framework.variableManager.getVariableValue(code.substr(1))
      @iCloudVerify = @_checkVerificationCode(code)
      @iCloudClient.verify = @iCloudVerify
      env.logger.info("Using verification code [#{@iCloudVerify}]")
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
      return Promise.resolve(@iCloudSuspended)

    _suspendState: (flag) =>
      return if @iCloudSuspended == flag
      @iCloudSuspended = flag
      @config.iCloudSuspended = @flag
      @emit 'suspended', @iCloudSuspended
      if @iCloudSwitch? and @iCloudSwitch instanceof env.devices.SwitchActuator
        @iCloudSwitch.changeStateTo(! @iCloudSuspended)
      state = if flag then 'disabled' else 'enabled'
      env.logger.info("iCloud location updates for \"#{@iCloudDevice}\" #{state}")
      return Promise.resolve(flag)

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
      if @iCloudSuspended
        env.logger.debug("Location update for \"#{@iCloudDevice}\" suspended. \
          Skipping refresh call ...")
      else
        @_refreshClient().catch(() -> return false)
        return true

  return plugin
