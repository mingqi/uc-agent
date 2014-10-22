logcola = require 'logcola'
os = require 'os'
moment = require 'moment'
findtime = require 'findtime'

module.exports = (config) ->

  _tail = logcola.plugins.Tail(config)

  _line_buff = {}
  _emit = null
  _interval_obj = null 

  _getBuff = (file) ->
    if not _line_buff[file]
      _line_buff[file] = []
    return _line_buff[file]

  _tail.line = (file, line, callback) ->
    buff = _getBuff(file)
    if findtime(line) and buff.length > 0
      console.log "mmmmmmmmmmmmm: #{line}"
      console.log findtime(line)
      ## merge all message in buff to one line
      message = buff.map((item) -> item[1]).join('\n')
      callback null, {
          tag: 'log' 
          record:
            path: file
            message: message
            host: os.hostname()
            event_timestamp: buff[0][0]
            tz_offset: moment().zone()
          }
      buff.length = 0
    buff.push [(new Date()).getTime(), line]

    if buff.length > 100
      ## too many line was buffered, consider them as non mulitple line
      for [timestamp, message] in buff
        callback null, {
          tag: 'log' 
          record:
            path: file
            message: message
            host: os.hostname()
            event_timestamp: timestamp
            tz_offset: moment().zone()
          }
      buff.length = 0


  _cleanup = (full) ->
    for file, buff of _line_buff
      curr_time = (new Date()).getTime()
      if full or (buff.length > 0 and (curr_time - buff[0][0]) > 5000)
        for [timestamp, message] in buff
          _emit {
            tag: 'log' 
            record:
              path: file
              message: message
              host: os.hostname()
              event_timestamp: timestamp
              tz_offset: moment().zone()          
          }
        buff.length = 0


  return {
    start : (emit, callback) ->
      _emit = emit
      setInterval () ->
        logger.debug "to cleanup tail multiple line buffer"
        _cleanup(false)
      , 1000
      
      _tail.start emit, callback
    
    
    shutdown : (callback) ->
      _tail.shutdown () ->
        _cleanup(true)
        clearInterval(_interval_obj) if _interval_obj
        callback()
  }

  return _tail
  