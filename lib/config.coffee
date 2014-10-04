fs = require 'fs'
glob = require 'glob'
path = require 'path'
us = require 'underscore'
os = require 'os'
http = require 'http'
VError = require('verror');
zlib = require 'zlib'
hoconfig = require 'hoconfig-js'
util = require './util'
us = require 'underscore'
async = require 'async'

exports.local = local = (local_path, cb) ->
  if not fs.existsSync(local_path)
    return cb(new Error("not exists dir or file on #{local_path}"))

  stat = fs.statSync(local_path) 
  if stat.isFile()
    config = hoconfig(local_path)
  else
    config = us.reduce(
      glob.sync(path.join(local_path, '*.conf')),
      (c, file) ->
        us.extend(c, hoconfig(file))
      , 
      {}) 
  config = for monitor, config_item of config
    us.extend(config_item, {monitor: monitor}) 
  cb(null, config)


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
      ssl: true
      host: options.host 
      port: options.port
      method: 'GET'
      path: /logfiles/+options.agent_id
      headers : {
        'licenseKey' : options.license_key
      }
    }
  , (err, status, result) ->
      if err
        logger.error err
        return cb(new VError(err, "failed to call remote service grab montior list"))       
      if status != 200
        return cb(new Error("call /montor return error status #{status}"))
      cb(null, result)
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
          callback(new VError(err, "failed to backup config to local #{backup_path}"))      
        else
          callback(null, config)
      )

exports.merge = merge = ( args... ) ->
  callback = args[args.length - 1] 
  if args.length < 3
    return callback(new Error('wrong argument pass to merge function, at less three input'))  
  
  async.reduce(
    args[..-2]
  , []
  , (memo, configer, callback) ->
      configer (err, config) ->
        if err
          callback(err)
        else
          callback(err, memo.concat(config))
  , callback)

