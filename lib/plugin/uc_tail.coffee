logcola = require 'logcola'
os = require 'os'
moment = require 'moment'

module.exports = (config) ->

  tail = logcola.plugins.Tail(config)

  tail.line = (file, line, callback) ->
    callback null, {
      tag: 'log' 
      record:
        path: file
        message: line
        host: os.hostname()
        event_timestamp: (new Date()).getTime()
        tz_offset: moment().zone()
      }

  return tail
  