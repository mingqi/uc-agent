http = require 'http'
zlib = require 'zlib'
buffer = require '../buffer'
VError = require('verror');
util = require '../util'

###
remote_host
remote_port
license_key

# buffer config
....

###

Upload = (config) ->
  remote_host = config.remote_host
  remote_port = config.remote_port
  remote_uri = config.uri

  return {
    
    start : (callback) ->
      logger.info "upload plugin for #{config.uri} starting..."
      callback()    

    shutdown : (callback) ->
      callback()

    writeChunk : (chunk, callback) ->
      body = []
      for {tag, record, time} in chunk
        body.push(record)

      util.rest({
        ssl: true
        host: remote_host
        port: remote_port
        method: 'POST'
        path: remote_uri 
        headers : {
          'licenseKey' : config.license_key
          }               
        }
      , JSON.stringify(body)
      , (err, status, result) ->
          if err
            callback(new VError(err, "failure on send data to #{remote_host}:#{remote_port}")) 
          else
            if status != 200
              callback(new Error("upload service return error response, status=#{status}"))
            else
              callback()
        )
  }


module.exports = (config) -> 
  buffer(config, Upload(config))
