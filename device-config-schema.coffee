module.exports = {
  title: "Pimatic phone device config schema"
  PhoneDevice:
    title: "Phone device config"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      serial:
        description: "Serial number of device"
        type: "string"
  PhoneDeviceIOS:
    title: "iPhone device configuration"
    type: "object"
    extensions: ["xAttributeOptions"]
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
}
