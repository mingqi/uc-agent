http = require 'http'
zlib = require 'zlib'
logcola = require 'logcola'
VError = require('verror');

util = require '../util'


###
- host
- port
- uri
- license_key

# buffer config: see logcola.Buffer

###

UCUpload = (config) ->
  _host = config.host
  _port = config.port
  _uri = config.uri
  _ssl = config.ssl
  _license_key = config.license_key

  logger.debug "license_keyyyy=#{_license_key}"

  return {
    
    start : (callback) ->
      logger.info "remote plugin for #{config.uri} starting..."
      callback()    

    shutdown : (callback) ->
      logger.info "remote plugin for #{config.uri} shutdown..."
      callback()

    writeChunk : (chunk, callback) ->
      body = []
      for {tag, record, time} in chunk
        body.push(record)

      util.rest({
        ssl: _ssl
        host: _host
        port: _port
        method: 'POST'
        path: _uri 
        headers : {
          'licenseKey' : config.license_key
          }               
        }
      , JSON.stringify(body)
      , (err, status, result) ->
          if err
            callback(new VError(err, "failure on send data to #{_host}:#{_port}/#{_uri}")) 
          else
            if status != 200
              callback(new Error("upload service return error response, status=#{status}"))
            else
              callback()
        )
  }


module.exports = (config) -> 
  logcola.Buffer(config, UCUpload(config))
