module.exports = {
  title: "Plugin config options"
  type: "object"
  properties:
    debug:
      description: "Enable debugging"
      type: "boolean"
      default: false
    timeformat:
      description: "Time format specification"
      type: "string"
      default: "YYYY-MM-DD hh:mm:ss"
}
