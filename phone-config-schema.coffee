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
          tags:
            description: "Location tags"
            type: "array"
            default: []
            items:
              description: "Tag item"
              type: "string"
          ssids:
            description: "WiFi SSIDs"
            type: "array"
            default: []
            items:
              description: "WiFi SSID"
              type: "string"
          gpss:
            description: "GPS entries"
            type: "array"
            default: []
            items:
              description: "GPS entry"
              type: "object"
              properties:
                lat:
                  description: "Latitude"
                  type: "number"
                long:
                  description: "Longitude"
                  type: "number"
                radius:
                  description: "Radius (meter)"
                  type: "number"
                  unit: "m"
          gsm:
            description: "GSM phone cell"
            type: "object"
            properties:
              mnc:
                description: "Mobile network code"
                type: "string"
              mcc:
                description: "Mobile country code"
                type: "string"
              cids:
                description: "Cell tower IDs"
                type: "array"
                default: []
                items:
                  description: "Location area code and cell ID"
                  type: "object"
                  properties:
                    lac:
                      description: "Local area code"
                      type: "string"
                    cid:
                      description: "Cell IDs"
                      type: "string"
}
