os = require 'os'
util = require './util'

PluginReport = (emit, monitorId) ->
  last_status = null
  last_message = null
  timestamp = null

  return (status, message) ->
    curr_timestamp = util.systemTime()

    if last_status != status or last_message != message or !timestamp or (curr_timestamp - timestamp) > 60 * 1000
      last_status = status
      last_message = message
      timestamp = curr_timestamp
      emit({
        tag : 'report' 
        record : {
          hostname: os.hostname()
          monitorId: monitorId, 
          status: status, 
          message: message}
        }) 
     
exports.PluginReport = PluginReport