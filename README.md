[![Build Status](http://img.shields.io/travis/bstrebel/pimatic-phone/master.svg)](https://travis-ci.org/bstrebel/pimatic-phone)
[![Version](https://img.shields.io/npm/v/pimatic-phone.svg)](https://img.shields.io/npm/v/pimatic-phone.svg)
[![downloads][downloads-image]][downloads-url]

[downloads-image]: https://img.shields.io/npm/dm/pimatic-phone.svg?style=flat
[downloads-url]: https://npmjs.org/package/pimatic-phone

pimatic-phone
=============

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/screenshots/frontend.png" width="1020">

A generic pimatic plugin for mobile devices to provide location based
devices. Continuous GPS tracking and reverse geocoding are expensive in
terms of mobile power consumption and Google/OSM API requests. Many
location based rules will work well with known locations like "Home" or
"Office". The plugin was inspired by the [pimatic-locatin-plugin](https://pimatic.org/plugins/pimatic-location/) but uses a
different device layout and (as of Rev. 0.6.0) a session based iCloud client
from [icloud-promise](https://www.npmjs.com/package/icloud-promise) for **iOS** devices.

The signature of the _updateLocation_ API call provides compatibility
with the Android App [PimaticLocation](https://github.com/Oitzu/pimatic-location).

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/screenshots/iframe.png" width="1020">

With revision Rev. 0.8.0 an iframeDevice from pimatic-iframe can be utilized
to show the current location on a map. Default settings use the Google Maps Embed API.
You have to register a project at the [Google Developer Console](https://console.developers.google.com) and
generate an API key.

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/screenshots/config.png" width="480">


**Some remarks on iOS devices**

- Notification emails: A notification email from Apple is generated when
    the iCloud session is established on pimatic startup/device creation.

- Update interval (I): Requesting location information from the iPhone triggers
    the device to push the data to the iCloud. A short period increases
    power consumption significantly and may drain your battery.

- Update interval (II): Use rules and the pimatic-phone API to suspend location
    updates, e.g. if the device is connected to WiFi at home: Use [pimatic-ping](https://pimatic.org/plugins/pimatic-ping/)
    or [pimatic-cron](https://pimatic.org/plugins/pimatic-cron/) to trigger the suspend by executing (inspired by a request
    at the [pimatic forum](https://forum.pimatic.org/topic/2719/pimatic-phone-icloud-error/37)). This feature could not be used if you have
    two factor authentication activated. See 2FA remarks (see below).
    As of Rev. 0.8.0 you can easily define a DummySwitch to enable/disable
    iCloud updates through the mobile frontend

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/screenshots/switch.png" width="480">

```
    curl --user "admin:admin" --silent --request GET \
    http://localhost:8080/api/device/<IPHONE>/suspend?flag=true
```

- Session ID and cookies are not permanently stored but recreated at
    pimatic startup/iOS device initialisation. Their is no automatic reconnect
    of sessions to avoid flooding with notification mails due to configuration
    issues or other problems. In case of an error and a lost connection
    open the configuration dialog of the device. A new session is established
    when you recreate the device by clicking the save button. Their is no need
    to restart pimatic.

- Two factor authentication (2FA): If activated, a notification dialog pops up
    on your device requiring a confirmation for the session. Also a
    verification code is displayed. It seems that neither the confirmation
    nor the verification code is really necessary to access the iCloud device
    information. You can avoid this messages by generating a verification
    code on your iPhone (Settings -> iCloud -> Apple ID -> Security
    -> Verification Code) and use this code in the iCloudVerify configuration
    option. Currently their is no possibility to refresh 2FA sessions.
    Keep your iCloudInterval lesser then the session timeout of 600 seconds.
    As of Rev. 0.7.6 additional API calls (enable/disableUpdates, see API
    documentation below) may be used to suspend updates for 2FA sessions.
    Due to limitations of the iCloud API logout and login calls have to be
    performed and Apple notification mails are triggered by the enableUpdates
    call. You have to provide a valid verification code or '000000' as in
    https://.../enableUpdates?code=000000


As of Rev. 0.4.6 an additional API call _updatePhone_ provides a simple to use
interface for **Android** devices running the Tasker APP. Download and import the
[sample project](https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/Pimatic.prj.xml) to Tasker and change the server settings in the HTTP Get task.
See the [Tasker Setup Guide](https://github.com/bstrebel/pimatic-phone/blob/master/assets/TaskerSetup.md) for details.

The location map allows you to define such well known location tags and
let you use the most suitable method (native apps, tasker jobs, GPS/GSM
tracking, WLAN connections, etc.) to update the location of a mobile
device. Location tags are similar to geofences and client apps like [Locative](https://github.com/LocativeHQ)
for [iOS](https://itunes.apple.com/de/app/locative/id725198453?mt=8) or [Android](https://play.google.com/store/apps/details?id=io.locative.app&hl=de) can be used to update the device location with the new
 GET requests _enter_ and _exit_. See API documentation below for details.

As of revision 0.7.5 all API calls return the current device location on
success.
```json
{
  "result":
  {
    "tag":"Home",
    "source":"TAG",
    "type":"API",
    "time":"2017-02-02 15:47:05",
    "utc":1486046825540,    
    "gps":
    {
      "latitude":53.12345678,
      "longitude":10.87654321
    }
  },
  "success":true
}
```
Also two additional api calls _fetchLocation_ and _fetchPreviousLocation_
are implemented to provide the location information by simple GET requests.
See the API documentation below for details.


Location based rules
--------------------
No additional predicates or rule actions are provided in the moment but
you can use dynamically generated device variables and attributes, e.g.

```
when $phone.location gets updated and $phone.tag != "Home" then turn lights off
when location of phone is equal to "Office" then log "at work"
when $phone.distanceToHome is lower than 500 then log "almost at home"
...
```

Overlapping locations
---------------------
As of Rev. 0.4.2 overlapping locations are supported. You can, for
example, define a location "home" with latitude=0, longitude=0 and
radius=250m and a location "near home" with the same gps data but a
radius of 1000m. A distance of 200m will provide the location "home",
500m give you "near home".


Use xLinks to open maps for device location (experimental)
----------------------------------------------------------
As of Rev. 0.4.0 you can define URL templates to open Google Maps or
Open Street Map for the current device location:

```coffeescript
      xLinkTemplate:
        description: "URL template"
        type: "string"
        default: "https://www.google.com/maps?q={latitude}+{longitude}"
```

Limitations: The values are not updated in the frontend. You have to
manually refresh the browser window.


Plugin configuration
--------------------

Provides a location table to map geo locations (GPS), mobile cell tower
positions (GSM) and WiFi connections (SSID) to user defined location
tags

```coffeescript
  "plugins": [
    {
      "locations": [
        {
          "name": "office",
          "tag": "Office",
          "ssids": [
            "DIGITEC-GAST"
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
            "AVM",
            "ASUS"
          ],
          "gps": {
            "latitude": 53.66,
            "longitude": 10.08,
            "radius": 250
          },
          "cids": [
            "GSM:42441.5453313",
            "GSM:1401.43266781",
            "GSM:411.13021"
          ]
        }
      ],
      "plugin": "phone",
      "active": true,
      "debug": true
    }
  ],
```

Devices
-------

Device specific configuration

**PhoneDevice:** Generic mobile device, updates it's location via API
calls (Tasker scripts, Apps)

```json
    {
      "serial": "HTC0815",
      "xAttributeOptions": [],
      "id": "phone_htc-m9",
      "name": "ViperOneM9",
      "class": "PhoneDevice"
    }
```

**PhoneDeviceIOS:** Apple mobile devices, uses icloud-promise API to update
the location periodically

```coffeescript
    {
      "iCloudUser": "user@domain",
      "iCloudPass": "password",
      "iCloudDevice": "Users iPhone",
      "xAttributeOptions": [],
      "id": "phone_user",
      "name": "Users iPad",
      "class": "PhoneDeviceIOS",
      "debug": true,
      "accuracy": 500
    }
```

Device configuration option details

```coffeescript

  PhoneDevice:
    title: "Phone device config"
    type: "object"
    extensions: ["xAttributeOptions", "xLink"]
    properties:
      serial:
        description: "Serial number of device"
        type: "string"
        default: ""
      debug:
        description: "Enable debug output"
        type: "boolean"
        default: false
      accuracy:
        description: "Radius (m) for GPS mapping"
        type: "number"
        default: 250
      xLinkTemplate:
        description: "URL template"
        type: "string"
        default: "https://www.google.com/maps?q={latitude}+{longitude}"

  PhoneDeviceIOS:
    title: "iPhone device configuration"
    type: "object"
    extensions: ["xAttributeOptions", "xLink"]
    properties:
      iCloudUser:
        description: "iCloud user (Apple ID)"
        type: "string"
        default: ""
      iCloudPass:
        description: "iCloud password"
        type: "string"
        default: ""
      iCloudVerify:
        description: "iCloud 2FA verification code"
        type: "string"
        default: "000000"
      iCloudDevice:
        description: "iCloud device name"
        type: "string"
        default: ""
      iCloudInterval:
        description: "iCloud poll interval (seconds)"
        type: "integer"
        default: 300
      iCloudSessionTimeout:
        description: "iCloud session expiration timeout"
        type: "integer"
        default: 600
      iCloudSuspended:
        description: "iCloud updates suspended"
        type: "boolean"
        default: false
      iCloudTimezone:
        description: "iCloud client timezone"
        type: "string"
        default: "Europe/Berlin"
      debug:
        description: "Enable debug output"
        type: "boolean"
        default: false
      accuracy:
        description: "Radius (m) for GPS mapping"
        type: "number"
        default: 250
      gpsLimit:
        description: "Log new position only if significantly moved"
        type: "number"
        default: 250
      xLinkTemplate:
        description: "URL template"
        type: "string"
        default: "https://www.google.com/maps?q={latitude}+{longitude}"

```

Attributes
----------

The following attributes are available and can be used for logging or
displayed in the frontend.

```coffeescript
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
      previousTag:
        description: "Previous location of the device"
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
      suspended:
        label: "Suspended"
        description: "iCloud updates suspended"
        type: t.boolean
        acronym: 'OFF'
        displaySparkline: false
        hidden: true        
```

Many of the attributes are volatile in nature. Adjust database logging
options according to your needs, e.g.:

```coffeescript
    "database": {
      "deviceAttributeLogging": [
        # ...
        {
          "deviceId": "phone_*",
          "attributeName": "*",
          "type": "*",
          "interval": "0",
          "expire": "0"
        },
        {
          "deviceId": "phone_*",
          "attributeName": "tag",
          "expire": "1y"
        },
        {
          "deviceId": "phone_*",
          "attributeName": "gps",
          "expire": "1y"
        }
      ],
      #...
    }

```
With Rev. 0.4.1 a new configuration option gpsLimit allows you to
restrict the logging: Updates are only written to the database when the
location tag changes or a significant movement > gpsLimit was detected
between two updates.

Device actions
--------------

Different actions/API calls can be used to update the device location.
Use HTTP(S) GET requests like
```
http(s)://<host>/api/device/<deviceId>/<action>?<key>=<value>[&<key>=<value]...
```
where <host> is the domain name/address of your pimatic instance,
<device> is the deviceId of your mobile and call is one of the following:

| call          | key(s)   | value  | comment                         |
|---------------|----------|--------|---------------------------------|
|updateTag|tag|location tag|set the location tag directly|
|enter|tag|location tag|set the location tag from geofence app|
|exit|tag|location tag|set the location tag from geofence app|
|updateGPS|latitude,longitude,accuracy,source|gps data|used internally for iCloud devices|
|updateCID|cid|%CELLID| Android tasker mobile cell ID|
|updateSSID|ssid|ssid|SSID of connected WLAN
|updateLocation|long,lat,updateAddress|gps data|legacy call for PimaticLocation Android App|
|updatePhone|serial,ssid,ssid,...|Tasker vasrs|see [documentation](https://github.com/bstrebel/pimatic-phone/blob/master/assets/TaskerSetup.md) for details|
|fetchLocation|n/a|n/a|return current device location|
|fetchPreviousLocation|n/a|n/a| return the previous location|
|suspend|flag|true/false, on/off|suspend location updates, iOS devices only!|
|disableUpdates|n/a|n/a|logout and disable updates for iOS devices with 2FA|
|enableUpdates|code (verification)|000000|login and enable updates for iOS devices with 2FA|

Example:
```
    curl --user "admin:admin" --silent --request GET \
    http://localhost:8080/api/device/<IPHONE>/enter?tag=Home
```

Available API call os of Rev. 0.7.5

```coffeescript
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
      suspend:
        description: "Suspend iCloud location updates"
        params:
          flag:
            type: t.string
      fetchLocation:
        description: "Return current device location"
      fetchPreviousLocation:
        description: "Return previous device location"
      disableUpdates:
        description: "Disable iCloud location updates"
      enableUpdates:
        description: "Enable iCloud location updates"
        params:
          code:
            description: "iCloud 2FA verification code code"
            type: t.string
```

TODO: detailed description of calls and params, curl examples, tasker
examples

Roadmap
-------

* ~~Generate HTML links to display device location in Google Maps~~
* ~~Generate HTML links to display device location in Open Street Map~~
* ~~Display current location in maps iframe (Google/OSM)~~
* ~~Add distance attribute (distance between geo locations)~~
* Use Google Maps and/or OSM for route calculations
* Add route attribute (routing distance road)

Changelog
---------

v0.8.2

- bugfix device recreation error


v0.8.0

- use pimatic-iframe for device location
- use DummySwitch for iCloud update suspend


v0.7.7

- bugfix device initialization from lastState

v0.7.6

- iCloudSuspended configuration attribute
- disable/enableUpdates API calls for 2FA sessions

v0.7.5

- API calls return JSON response
- support for previousLocation attributes
- additional API calls: enter, exit, fetchLocation, fetchPreviousLocation

v0.7.3

- force UI update on recreation of device
- additional device debugging output if enabled
- minor bugfixes

v0.7.2

- use refreshClient during initalization

v0.7.1

- validate device location (may be undefined) if location service
    is disabled


v0.7.0

- enhanced configuration options for iOS devices
- use icloud-promise module
- suspend iCloud location updates via AOI call

v0.6.3

- updated documentation

v0.6.1

- iOS support with session based iCloud client module


v0.5.0

- preliminary hot fix iOS device support


**2017-01-23: Support for iOS devices broken due to iCloud API changes!**


v0.4.6

- updatePhone API call for Android Tasker APP


v0.4.5

- initial grunt/mocha setup and travis integration

v0.4.4

- update location only on relevant changes
 - significant movements > gpsLimit (v0.4.1)
 - tag, source or type changes through API calls (new)

v0.4.3

- tag initialization on startup [[#1](https://github.com/bstrebel/pimatic-phone/issues/1)]

v0.4.2

- support for overlapping locations

v0.4.1

- update location only on significant movements > gpsLimit

v0.4.0

- xLink to location URL

v0.3.1

- Stable release with dynamic distance attributes
