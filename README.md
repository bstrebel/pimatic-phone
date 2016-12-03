pimatic-phone _[work in progress]_
==================================

A generic pimatic plugin for mobile devices to provide location based
 devices and predicates. Continous GPS tracking and reverse geocoding
 are expensive in terms of mobile power consumption and Google/OSM
 requests. Many location based rules will work with well known locations
 like "HOME", "OFFICE", ...

 The location map allows you to define such well known location tags and
 let you use the most suitable method (native apps, tasker jobs, GPS/GSM
 tracking, WLAN connections, etc.) to determine the location of a mobile
 device.

Plugin configuration
--------------------

Provides a location table to map geo locations (GPS), mobile cell tower
positions (GSM) and WiFi connections (SSID) to user defined location tags

    {
      "locations": [
        {
          "name": "office",
          "tag": "Office",
          "ssids": [
            "DIGITEC"
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
            "longitude": 10.07,
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

TODO: screenshots of plugin configuration


Devices
-------

Device specific configuration

**PhoneDevice:** Generic mobile device, updates it's location via API calls
(Tasker-Skripts, Apps)

**PhoneDeviceIOS:** Apple mobile devices, use fmip (find-my-iphone) service
to update location periodically

TODO:

Attributes
----------

The following attributes are available are used and can be used for logging
or displayed in the frontend

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

TODO: screenshot, explanations


Actions
-------

Actions to be to update the device location. Use HTTP(S) GET requests
https://pimatic/api/<phone-device-id>/<call>?<key>=<value> within nativ apps
or through tasker skripts.

Available API call os of Rev. 0.1.1

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

TODO: detailed description of calls and params, curl examples, tasker examples

