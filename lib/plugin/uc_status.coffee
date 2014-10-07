os = require 'os'
VERSION = require '../version'

module.exports = (config) ->

  _agent_id = config.agent_id
  _interval = config.interval

  logger.debug "uc_status's interval is #{_interval}"
  
  _interval_obj = null 

  return {
    
    start : (emit, callback) ->
      _interval_obj = setInterval () ->
        emit
          tag: 'status'
          record:
            agentId: _agent_id
            hostname: os.hostname()
            version: VERSION

      , _interval * 1000
      
      callback() 

    shutdown :  (callback) ->
      logger.info "uc_status shutdown"
      callback()
    
  }