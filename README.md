[![Build Status](http://img.shields.io/travis/bstrebel/pimatic-phone/master.svg)](https://travis-ci.org/bstrebel/pimatic-phone)
[![Version](https://img.shields.io/npm/v/pimatic-phone.svg)](https://img.shields.io/npm/v/pimatic-phone.svg)
[![downloads][downloads-image]][downloads-url]

[downloads-image]: https://img.shields.io/npm/dm/pimatic-phone.svg?style=flat
[downloads-url]: https://npmjs.org/package/pimatic-phone

pimatic-phone
=============

A generic pimatic plugin for mobile devices to provide location based
devices. Continuous GPS tracking and reverse geocoding are expensive in
terms of mobile power consumption and Google/OSM API requests. Many
location based rules will work well with known locations like "Home" or
"Office". The plugin was inspired by the [pimatic-location-plugin](https://pimatic.org/plugins/pimatic-location/) but uses a
different device layout and a reworked [find-my-iphone library](https://github.com/bstrebel/fmip) for iOS devices.
The signature of the _updateLocation_ API call provides compatibility with
the Android App [PimaticLocation](https://github.com/Oitzu/pimatic-location).

The location map allows you to define such well known location tags and
let you use the most suitable method (native apps, tasker jobs, GPS/GSM
tracking, WLAN connections, etc.) to update the location of a mobile
device.

Location based rules
--------------------
No additional predicates or rule actions are provided in the moment but
you can use dynamically generated device variables and attributes, e.g.

```
when $phone.location gets updated and $phone_htc.tag != "Home" then turn lights off
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


Use xLinks to open maps for device location
-------------------------------------------
As of Rev. 0.4.0 you can define URL templates to open Google Maps or
Open Street Map for tht current device location:

```
      xLinkTemplate:
        description: "URL template"
        type: "string"
        default: "https://www.google.com/maps?q={latitude}+{longitude}"
```


Plugin configuration
--------------------

Provides a location table to map geo locations (GPS), mobile cell tower
positions (GSM) and WiFi connections (SSID) to user defined location
tags

```
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
calls (Tasker-Skripts, Apps)

```
    {
      "serial": "HTC0815",
      "xAttributeOptions": [],
      "id": "phone_htc-m9",
      "name": "ViperOneM9",
      "class": "PhoneDevice"
    }
```

**PhoneDeviceIOS:** Apple mobile devices, use fmip (find-my-iphone)
service to update location periodically

```
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
    },
```

Attributes
----------

The following attributes are available are used and can be used for
logging or displayed in the frontend

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
      gpsLimit:
        description: "Log new position only if significantly moved"
        type: "number"
        default: 250
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

Many of the attributes are volatile in nature. Adjust database logging
options according to your needs, e.g.:

```json
    "database": {
      "deviceAttributeLogging": [
        ...
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
      ...
    },

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
http(s)://<host>/api/<device>/<call>?<key>=<value>[&<key>=<value]...
```
where <host> is the domain name/address of your pimatic instance,
<device> is the deviceId of your mobile and call is one of the following:

| call          | key(s)   | value  | comment                         |
|---------------|----------|--------|---------------------------------|
|updateTag|tag|location tag|set the location tag directly|
|updateGPS|latitude,longitude,accuracy,source|gps data|used internally for iCloud devices|
|updateCID|cid|%CELLID| Android tasker mobile cell ID|
|updateSSID|ssid|ssid|SSID of connected WLAN
|updateLocation|long,lat,updateAddress|gps data|legacy call for PimaticLocation Android App|

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

TODO: detailed description of calls and params, curl examples, tasker
examples

Roadmap
-------

* ~~Generate HTML links to display device location in Google Maps~~
* ~~Generate HTML links to display device location in Open Street Map~~
* Display current location in maps iframe (Google/OSM)
* ~~Add distance attribute (distance between geo locations)~~
* Use Google Maps and/or OSM for route calculations
* Add route attribute (routing distance road)

Changelog
---------

Rev. 0.4.1

* Log location only on significant movements > gpsLimit

Rev. 0.4.0

* xLink to location URL

Rev. 0.3.1

* Stable release with dynamic distance attributes
