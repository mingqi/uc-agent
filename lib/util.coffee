http = require 'http'
https = require 'https'
zlib = require 'zlib'
us = require 'underscore'
async = require 'async'  
running = require('is-running')
spawn = require('child_process').spawn
fs = require 'fs'
path = require 'path'
moment = require 'moment'
humanFormat = require 'human-format'
VError = require('verror');


exports.systemTime = systemTime = () ->
  (new Date()).getTime()

exports.wait = wait = (interval, timeout, test, callback) =>
  started_time = systemTime()
  async.whilst(
    () ->
      return !test() and (systemTime() - started_time) < timeout
  , (callback) ->
      setTimeout(callback, interval)         
  , () ->
      if test()
        callback(null, true)
      else
        callback(null, false)
    )
        
exports.kill = kill = (pid, timeout, callback) ->
  killTime = systemTime()
  try
    process.kill(pid, "SIGTERM")
  catch e
    if e.code == 'EPERM'
      return callback(new Error('no permission to kill process'))

  wait(100, timeout
  , () ->
      not running(pid) 
  , (err, not_running) ->
      if not not_running    
        process.kill(pid, "SIGKILL")
      callback() 
  ) 


exports.findPath = findPath = (base_dir, p) ->
  while(true)
    pp = path.join(base_dir, p)
    if fs.existsSync pp
      return pp 

    break if base_dir == '/'
    base_dir = path.dirname(base_dir)

  return null

exports.dateISOFormat = dateISOFormat = (d) ->
  moment(d).format('YYYY-MM-DDTHH:mm:ssZ')

exports.emitTSD = (emit, metric, value, timestamp, dimensions) ->
  emit(
    tag: 'tsd',
    record: 
      metric : metric
      value : value
      timestamp : dateISOFormat(timestamp || new Date() )  
      dimensions : dimensions || {}
  )


exports.rest = (options, body, callback) ->
  logger.debug "http restful call: #{JSON.stringify options}"
  if not callback
    callback = body
    body = null

  options.headers ||= {}
  us.extend(options.headers, {'Accept-Encoding' : 'gzip'})

  if body
    us.extend(options.headers, {
      'Content-Type' : 'application/json',
      'Content-Encoding' : 'gzip'})
    if not us.isString(body)
      body = JSON.stringify(body)

  buffs = []
  http_module = if options.ssl then https else http
  request = http_module.request(options, (response) ->
    response.on('data', (chunk) ->
      buffs.push chunk    
    )

    response.on('end',  () ->
      buffer = Buffer.concat(buffs);
      result = null
      if buffer.length > 0
        if response.headers['content-encoding'] == 'gzip'
          zlib.gunzip(buffer, (err, result) ->
            if err
              return callback(new Error('illegal gzip content'))
            else
              try
                r = JSON.parse(result)
              catch e
                callback(new Error("bad response, not JSON formant: #{result}"))      
              callback(null, response.statusCode, r) 
              
          ) 
        else
          try
            result = JSON.parse(buffer.toString())
            callback(null, response.statusCode, result) 
          catch e
            callback(new Error("bad response, not JSON formant: #{buffer.toString()}"))      
      else
        callback(null, response.statusCode)
    )
  )

  request.on('error', (e) ->
    callback(new VError(e, "http restful cal fialure, reqeust options: #{JSON.stringify options}, error: #{e.message}"))  
  )

  if body
    zlib.gzip(body, (err, result) ->
        request.write(result);
        request.end()
      )
  else
    request.end()

exports.parseHumaneSize = (ssize) ->
  lower_opts = 
    unit: 'b'
    prefixes: humanFormat.makePrefixes(',k,m,g,t'.split(','), 1024 )

  upper_opts = 
    unit: 'B'
    prefixes: humanFormat.makePrefixes(',K,M,G,T'.split(','), 1024 )
  
  value = humanFormat.parse(ssize, lower_opts) or humanFormat.parse(ssize, upper_opts)

  if not value
    throw new Error("illegal size format: #{ssize}")
  return value