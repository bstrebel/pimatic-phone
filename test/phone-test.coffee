assert = require 'cassert'
_ = require 'lodash'

describe "[pimatic]", ->

  framework = null
  env = null
  # url = null
  # locations = null

  config =
    settings:
      debug: true
      logLevel: "debug"
      httpServer:
        enabled: true
        port: 8080
      httpsServer: {}
      database:
        client: "sqlite3"
        connection: {
          filename: ':memory:'
        }
    plugins: [
      {
        "locations": [
          {
            "name": "office",
            "tag": "Office",
            "ssids": [
              "OFFICE"
            ],
            "gps": {
              "latitude": 53.5544809,
              "longitude": 9.9786172,
              "radius": 250
            },
            "cids": [
              "GSM:42407.5455365",
              "GSM:1401.43266861",
              "GSM:42407.5455361"
            ]
          },
          {
            "name": "home",
            "tag": "Home",
            "ssids": [
              "HOME"
            ],
            "gps": {
              "latitude": 53.658156,
              "longitude": 10.087347,
              "radius": 250
            },
            "cids": [
              "GSM:42441.5453313",
              "GSM:1401.43266781",
              "GSM:411.13021"
            ]
          },
          {
            "name": "mall",
            "tag": "AEZ",
            "ssids": [],
            "gps": {
              "latitude": 53.6543899,
              "longitude": 10.0885968,
              "radius": 250
            },
            "cids": []
          },
          {
            "name": "train",
            "tag": "S-Bahn",
            "ssids": [],
            "gps": {
              "latitude": 53.652371,
              "longitude": 10.0896482,
              "radius": 250
            },
            "cids": []
          },
          {
            "name": "change",
            "tag": "Ohlsdorf",
            "ssids": [],
            "gps": {
              "latitude": 53.6227401,
              "longitude": 10.0329287,
              "radius": 250
            },
            "cids": []
          },
        ],
        "plugin": "phone",
        "active": true,
        "debug": true
      }
    ]
    devices: [
      {
        "id": "phone",
        "name": "phone",
        "class": "PhoneDevice",
        "debug": true,
      }
    ]
    rules: []
    users: [
      {
        username: "admin",
        password: "admin",
        role: "admin"
      }
    ],
    roles: [
      {
        name: "admin",
        permissions: {
          pages: "write",
          rules: "write",
          variables: "write",
          messages: "write",
          events: "write",
          devices: "write",
          groups: "write",
          plugins: "write",
          updates: "write",
          database: "write",
          config: "write",
          controlDevices: true,
          restart: true
        }
      }
    ],
    variables: []

  fs = require 'fs'
  os = require 'os'
  configFile = "#{os.tmpdir()}/pimatic-test-config.json"

  before ->

    # TODO: check environment for ICLOUD_* and add iPhone device for testing

    fs.writeFileSync configFile, JSON.stringify(config)
    process.env.PIMATIC_CONFIG = configFile
    startup = require('./startup')
    env = startup.env
    startup.startup()
      .then( (fw) ->
        framework = fw
        # env.logger.info("Startup completed ...")
    ).catch( (err) -> env.logger.error(err))

  after ->
    fs.unlinkSync configFile

  describe "[startup]", ->

    url = "http://localhost:#{config.settings.httpServer.port}"

    if config.settings.httpServer.enabled

      it "httpServer should run", (done) ->
        http = require 'http'
        http.get(url, (result) ->
          done()
        ).on "error", (e) ->
          throw e

      it "httpServer should ask for password", (done)->
        http = require 'http'
        http.get(url, (result) ->
          assert result.statusCode is 401 # is Unauthorized
          done()
        ).on "error", (e) ->
          throw e

    else
      it "should be initialized", ->
        assert framework?

  describe "[plugin]", ->

    pluginConfig = null

    it 'should have locations configuration', (done) ->
      pluginConfig = framework.pluginManager.getPluginConfig('phone')
      assert pluginConfig?.locations
      done()

    describe "[phone]", ->

      # locations = framework.pluginManager.getPluginConfig('phone').locations
      http = require 'http'
      phone = null

      phoneRequest = (path, callback) ->
        opts = {
          port: parseInt(config.settings.httpServer.port)
          auth: "admin:admin"
          path: path
        }
        console.log("")
        req = http.get opts, (res) ->
          body = ""
          res.on "data", (chunk) ->
            body += chunk.toString()
          res.on "end", () ->
            return callback(body)
        req.on "error", (e) ->
          throw e

      phoneStatus = (deviceId) ->
        # phone = framework.deviceManager.getDeviceById(deviceId)
        console.log """
          status: id=#{phone.id} tag=#{phone._tag} src=#{phone._source} type=#{phone._type} \
                  lat=#{phone._latitude} long=#{phone._longitude}
          """

      phoneLocation = (tag) ->
        return _.find pluginConfig?.locations, (location) ->
          location.tag == tag

      phoneCheckLocation = (deviceId, tag) ->
        # phone = framework.deviceManager.getDeviceById(deviceId)
        return (
          phone._tag == tag and
            phone._latitude == phoneLocation(tag).gps.latitude and
            phone._longitude == phoneLocation("Home").gps.longitude
        )

      phoneLOC = (tag) ->
        gps = phoneLocation(tag).gps
        return "#{gps.latitude},#{gps.longitude},#{gps.radius}"

      it "device should be available", (done) ->
        phone = framework.deviceManager.getDeviceById("phone")
        assert phone?
        done()

      describe "[updateTag]", ->

        it "should set initial location to \"Home\"", (done) ->
          phoneRequest "/api/device/phone/updateTag?tag=Home", (body) ->
            assert JSON.parse(body).success
            phoneStatus("phone")
            phoneCheckLocation("phone", "Home")
            done()

        it "should change location tag to \"Office\"", (done) ->
          phoneRequest "/api/device/phone/updateTag?tag=Office", (body) ->
            assert JSON.parse(body).success
            phoneStatus("phone")
            phoneCheckLocation("phone", "Office")
            done()

        it "should change location tag to \"Office\"", (done) ->
          phoneRequest "/api/device/phone/updateTag?tag=Office", (body) ->
            assert JSON.parse(body).success
            phoneStatus()
            phoneCheckLocation("Office")
            done()

      describe "[updatePhone]", ->

        path = "/api/device/phone/updatePhone"
        serial = "0815"

        ssid = "%SSID"
        cellid = "%CELLID"
        locn = "%LOCN"
        loc = "%LOC"

        it "should set location to \"Home\" by %SSID", (done) ->

          ssid = "HOME"
          cellid = "%CELLID"
          locn = "%LOCN"
          loc = "%LOC"

          parms = "?serial=#{serial}&ssid=#{ssid}&cellid=#{cellid}&locn=#{locn}&loc=#{loc}"
          phoneRequest path+parms, (body) ->
            assert JSON.parse(body).success
            phoneStatus("phone")
            phoneCheckLocation("phone", "Home")
            done()

        it "should set location to \"Office\" by %LOCN", (done) ->

          ssid = "UNKNOWN"
          cellid = "%CELLID"
          locn = phoneLOC("Office")
          loc = "%LOC"

          parms = "?serial=#{serial}&ssid=#{ssid}&cellid=#{cellid}&locn=#{locn}&loc=#{loc}"
          phoneRequest path+parms, (body) ->
            assert JSON.parse(body).success
            phoneStatus("phone")
            phoneCheckLocation("phone", "Home")
            done()

        it "should set location to \"Home\" by %LOC", (done) ->

          ssid = "UNKNOWN"
          cellid = "%CELLID"
          loc = phoneLOC("Office")
          locn = "%LOCN"

          parms = "?serial=#{serial}&ssid=#{ssid}&cellid=#{cellid}&locn=#{locn}&loc=#{loc}"
          phoneRequest path+parms, (body) ->
            assert JSON.parse(body).success
            phoneStatus("phone")
            phoneCheckLocation("phone", "Home")
            done()
