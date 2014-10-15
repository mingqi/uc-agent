module.exports = () ->
  
  return {
    
    start : (cb) ->
      console.log "uc_debug start"
      cb()

    write : ({tag, record, time}) ->
      logger.debug "stdout: tag=#{tag}, record=#{JSON.stringify(record)}"
    
    shutdown : (cb) ->
      console.log "uc_debug shutdown..."          
      cb()
  }
