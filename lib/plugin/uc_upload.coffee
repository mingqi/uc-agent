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

module.exports = (config) ->
  _host = config.host
  _port = config.port
  _uri = config.uri
  _ssl = config.ssl
  _license_key = config.license_key

  _buffer = new logcola.Buffer(config)
  _buffer.writeChunk = (chunk, callback) ->
    body = []
    for {tag, record, time} in chunk
      body.push(record)

    logger.info "sending #{body.length} data to remote server #{_uri}"
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
          logger.warn "failure on send data to #{_uri}"
          callback(new VError(err, "failure on send data to #{_host}:#{_port}/#{_uri}")) 
        else
          if status != 200
            logger.warn "remote server response #{status}"
            callback(new Error("upload service return error response, status=#{status}"))
          else
            logger.info "success send #{body.length} data"
            callback()
      )

  return {
    
    start : (callback) ->
      logger.info "remote plugin for #{config.uri} starting..."
      callback()    

    shutdown : (callback) ->
      logger.info "remote plugin for #{config.uri} shutdown..."
      callback()

    write : _buffer.write

  }
