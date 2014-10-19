os = require 'os'
VERSION = require '../version'

module.exports = (config) ->

  _agent_id = config.agent_id
  _interval = config.interval

  logger.debug "uc_status's interval is #{_interval}"
  
  _interval_obj = null 

  return {
    
    start : (emit, callback) ->
      _send_status = () ->
        emit
          tag: 'status'
          record:
            agentId: _agent_id
            hostname: os.hostname()
            version: VERSION

      _send_status()
      _interval_obj = setInterval _send_status, _interval
      logger.info "uc_status started"
      callback() 

    shutdown :  (callback) ->
      logger.info "uc_status shutdown"
      callback()
    
  }