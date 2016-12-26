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
      iCloudDevice:
        description: "iCloud device name"
        type: "string"
        default: ""
      iCloudInterval:
        description: "iCloud poll interval (seconds)"
        type: "integer"
        default: 60
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
}
