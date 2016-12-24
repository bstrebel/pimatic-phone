assert = require 'cassert'
_ = require 'lodash'

describe "[pimatic]", ->

  framework = null
  env = null

  config =
    settings:
      debug: true
      logLevel: "debug"
      httpServer:
        enabled: false
        port: 8080
      httpsServer: {}
      database:
        client: "sqlite3"
        connection: {
          filename: ':memory:'
        }
    plugins: []
    devices: []
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

  deviceConfig = null

  describe "[startup]", ->

    if config.settings.httpServer.enabled

      it "httpServer should run", (done) ->
        http = require 'http'
        http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
          done()
        ).on "error", (e) ->
          throw e

      it "httpServer should ask for password", (done)->
        http = require 'http'
        http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
          assert res.statusCode is 401 # is Unauthorized
          done()
        ).on "error", (e) ->
          throw e

    else
      it "should be initialized", ->
        assert framework?
