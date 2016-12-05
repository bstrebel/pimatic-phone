module.exports = {
  title: "Plugin config options"
  type: "object"
  properties:
    debug:
      description: "Enable debug output"
      type: "boolean"
      default: false
    timeformat:
      description: "Time format specification"
      type: "string"
      default: "YYYY-MM-DD hh:mm:ss"
    homelocation:
      description: "Tag of the home location"
      type: "string"
      default: "Home"
    locations:
      description: "Location lookup map"
      type: "array"
      default: []
      items:
        description: "Location entry"
        type: "object"
        properties:
          name:
            description: "Name of the location map entry"
            type: "string"
          tag:
            description: "Location tag"
            type: "string"
          ssids:
            description: "WiFi SSIDs"
            type: "array"
            default: []
            items:
              description: "WiFi SSID"
              type: "string"
          gps:
            description: "GPS entry"
            type: "object"
            properties:
              latitude:
                description: "Latitude"
                type: "number"
              longitude:
                description: "Longitude"
                type: "number"
              radius:
                description: "Radius (meter)"
                type: "number"
                unit: "m"
          cids:
            description: "Cell tower IDs"
            type: "array"
            default: []
            items:
              description: "Cell ID"
              type: "string"
}
