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
}
