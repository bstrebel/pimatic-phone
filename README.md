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

Devices
-------

PhoneDevice
PhoneDeviceIOS

Predicates
----------

Examples:

    when "iPhone" is near HOME then ... 
    when "iPhone" is at HOME then ...
    when "iPhone" is not at HOME ...

Actions
-------

    
TODOs
-----



