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
    title: "iPhone debice configuration"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      iCloudUser:
        description: "iCloud User"
        type: "string"
        default: ""
      iCloudPass:
        description: "iCloud Password"
        type: "string"
        default: ""
      iCloudDevice:
        description: "iCloud Device"
        type: "string"
        default: ""
      iCloudInterval:
        description: "iCloud Interval"
        type: "integer"
        default: 60000
}
