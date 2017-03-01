module.exports = {
  title: "Pimatic phone device config schema"
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
      gpsLimit:
        description: "Log new position only if significantly moved"
        type: "number"
        default: 250
      googleMaps:
        description: "Optional Google Maps API options"
        type: "object"
        default: {}
        properties:
          key:
            description: "Optional Google API key to be used in the iFrame URL"
            type: "string"
            default: ""
          geocoding:
            description: "Lookup location for address"
            type: "boolean"
            default: true
          reverseGeocoding:
            description: "Lookup address for location"
            type: "boolean"
            default: true
      iFrame:
        description: "iFrame configuration"
        type: "object"
        default: {}
        properties:
          id:
            description: "iFrame device id"
            type: "string"
            default: ""
          url:
            description: "iFrame URL template"
            type: "string"
            default: "https://www.google.com/maps/embed/v1/place?key={key}&q={address}"
          enabled:
            description: "Enable iFrame updates"
            type: "boolean"
            default: false
          switch:
            description: "Optional enable switch device id"
            type: "string"
            default: ""
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
      iCloud2FA:
        description: "iCloud 2FA"
        type: "boolean"
        default: false
      iCloudVerify:
        description: "iCloud 2FA verification code"
        type: "string"
        default: "000000"
      iCloudVerifyVariable:
        description: "Name of the $variable providing the code"
        type: "string"
        default: ""
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
      iCloudSwitch:
        description: "iCloud suspend switch device id"
        type: "string"
        default: ""
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
      googleMaps:
        description: "Optional Google Maps API options"
        type: "object"
        default: {}
        properties:
          key:
            description: "Optional Google API key to be used in the iFrame URL"
            type: "string"
            default: ""
          geocoding:
            description: "Lookup location for address"
            type: "boolean"
            default: true
          reverseGeocoding:
            description: "Lookup address for location"
            type: "boolean"
            default: true
      iFrame:
        description: "iFrame configuration"
        type: "object"
        default: {}
        properties:
          id:
            description: "iFrame device id"
            type: "string"
            default: ""
          url:
            description: "iFrame URL template"
            type: "string"
            default: "https://www.google.com/maps/embed/v1/place?key={key}&q={address}"
          enabled:
            description: "Enable iFrame updates"
            type: "boolean"
            default: false
          switch:
            description: "Optional enable switch device id"
            type: "string"
            default: ""
      xLinkTemplate:
        description: "URL template"
        type: "string"
        default: "https://www.google.com/maps?q={latitude}+{longitude}"
}
