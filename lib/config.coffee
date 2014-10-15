fs = require 'fs'
path = require 'path'
us = require 'underscore'
os = require 'os'
http = require 'http'
VError = require('verror');
zlib = require 'zlib'
hoconfig = require 'hoconfig-js'
util = require './util'
us = require 'underscore'
async = require 'uclogs-async'

exports.local = local = (local_path, callback) ->
  if not fs.existsSync(local_path)
    return callback(null, [])

  content = fs.readFileSync(local_path, "utf-8")
  files = content.split('\n').map (line) ->
    line.trim()

  files = files.filter (f) ->
    f.length > 0 
  
  callback(null, files)


###
options:
  - host
  - port
  - agent_id
  - license_key
###
exports.remote = remote = (options, callback) ->
  util.rest(
    {
      ssl: options.ssl
      host: options.host 
      port: options.port
      method: 'GET'
      path: /config/+options.agent_id
      headers : {
        'licenseKey' : options.license_key
      }
    }
  , (err, status, result) ->
      if err
        logger.error err
        return callback(new VError(err, "failed to call remote service grab montior list"))       
      if status != 200
        return callback(new Error("call /config return error status #{status}"))

      logger.info "read file list from remote config: #{JSON.stringify result}"
      callback(null, result)
  )

exports.json = json = (local_path, callback) ->
  fs.readFile(local_path, {encoding: 'utf8'}, (err, data) ->
    if err
      return callback(new VError(err, "can't read local json config file #{local_path}"))
    try
      config = JSON.parse(data)
    catch e
      return callback(new Error("wrong json format of #{local_path}"))
    callback(null, config) 
  )


exports.backup = backup = (configer, backup_path, callback) ->
  configer (err, config) ->
    if err
      json(backup_path, callback)
    else
      fs.writeFile(backup_path, JSON.stringify(config), (err) ->
        if err
          throw new VError(err, "failed to backup config to local #{backup_path}")
        else
          callback(null, config)
      )

exports.merge = merge = ( args... ) ->
  callback = args[args.length - 1] 
  if args.length < 3
    throw new Error('wrong argument pass to merge function, at less three input')
  
  async.reduce(
    args[..-2]
  , []
  , (memo, configer, callback) ->
      configer (err, config) ->
        if err
          callback(err)
        else
          logger.debug "memo=#{memo}, config=#{config}"
          callback(err, memo.concat(config))
  , callback)

