Promise = require 'bluebird'
rp = require 'request-promise'
uuid = require 'node-uuid'
_ = require 'lodash'
# FileCookieStore = require 'tough-cookie-filestore'

class ICloudError extends Error
  constructor: (@message, @response) ->
    Error.captureStackTrace(@,@)

class Session

  home_endpoint: "https://www.icloud.com"
  setup_endpoint: "https://setup.icloud.com/setup/ws/1"
  user_agent: 'Opera/9.52 (X11; Linux i686; U; en)'
  client_build: '14E45'

  constructor: (client) ->
    @client = client
    @client_id = uuid.v1().toUpperCase()
    @cookies = rp.jar()
    @params =  {
      clientBuildNumber: @client_build
      clientId: @client_id
    }

  request: (endpoint, path, options) =>
    url = null
    switch endpoint
      when 'home' then url = @home_endpoint
      when 'setup' then url = @setup_endpoint
      else
        if @client.webservices?
          if @client.webservices[endpoint]
            service = @client.webservices[endpoint]
            url = service.url

    defaults = {
      uri: url + path
      jar: @cookies
      qs: @params
      json: true
      headers: {
        'Origin': @home_endpoint
        'Referer': @home_endpoint + "/"
        'User-Agent': @user_agent
      }
      resolveWithFullResponse: true
      simple: false
    }

    rp(_.merge(defaults, options))
    .then((response) =>
      # TODO: check iCloud response
      if response.statusCode == 200
        return Promise.resolve(response)
      else
        throw new ICloudError('ICloudError: ' + @client.errorMessage(response), response)
    ).catch((error) =>
      return Promise.reject(error)
    )

class Client

  # TODO: validate session an re-authentication
  # TODO: handle two factor authentication (?)

  constructor: (apple_id, password) ->
    @apple_id = apple_id
    @password = password
    @authenticated = false
    @session = new Session(@)
    @data = null
    @webservices = null
    @hsaChallengeRequired = null
    @devices = null

  getDevices: () =>
    return @devices

  login: () ->

    options = {
      method: 'POST'
      body: {
        apple_id: @apple_id
        password: @password
        extendend_login: false
      }
    }

    @session.request('setup', '/login', options)
    .then((response) =>
      if response.body?
        @hsaChallengeRequired = response.body.hsaChallengeRequired?
        @data = response.body
        if @data.dsInfo?.dsid?
          _.merge(@session.params, { dsid: @data.dsInfo.dsid })
        if @data.webservices?
          @webservices = @data.webservices
          @authenticated = true
      return Promise.resolve(response)
    )
    .catch( (error) =>
      return Promise.reject(error)
    )

  refreshClient: () =>
    endpoint = 'findme'
    path = '/fmipservice/client/web/refreshClient'
    options = {
      method: 'POST'
      body: {
        clientContext: {
          fmly: true
          shouldLocate: true
          selectedDevice: 'all'
        }
      }
    }
    @session.request(endpoint, path, options)
      .then( (response) =>
        @devices = response.body.content
        return Promise.resolve(response)
      )
      .catch( (err) =>
        return Promise.reject(err)
      )

  errorMessage: (error) =>
    message = ""
    if error.statusCode?
      if !!error.statusMessage
        message = error.statusMessage + " "
      else if !!error.reason
        message = error.reason + " "
      else if !!error.errorReason
        message = error.errorReason + " "
      else if !!error.error
        # TODO: check typeof error
        message = error.error + " "
      else
        message = "Unknown error" + " "
      message = message + "[#{error.statusCode}]"
    else
      message = error.toString()
    return message

  deviceNames: () =>
    devs = []
    devs.push(device.name) for device in @devices
    return devs

module.exports.Client = Client
module.exports.ICloudError = ICloudError