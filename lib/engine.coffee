Engine = require './engine'
UCTail = require './plugin/uc_tail'

us = require 'underscore'
hoconfig = require 'hoconfig-js'
path = require 'path'
fs = require 'fs'
md5 = require 'MD5'
async = require 'uclogs-async'
VError = require('verror')
logcola = require 'logcola'

_checksum = (paths) ->
  md5(paths.slice().sort().join(','))

###
engine_opts:
  - configer
  - inputs
  - outputs
  - config_refresh_interval

tail_opts:
  - pos_file
  - refresh_interval
###
module.exports = (engine_opts, tail_opts) -> 
  curr_paths_checksum = _checksum([])
  curr_tail = null
  engine = logcola.Engine()
  interval_obj = null

  for input in engine_opts.inputs
    engine.addInput(input)

  for [match, output] in engine_opts.outputs
    engine.addOutput(match, output)

  _refreshInput = () ->
    engine_opts.configer (err, paths) ->
      logger.info "new log file list from remote config is: #{paths}"
      if err
        logger.error err.stack
        return

      new_paths = paths
      new_paths_checksum =  _checksum(new_paths)

      if new_paths_checksum != curr_paths_checksum
        logger.info "log file list is chanrged,  need to refresh Tail to reflect changes"
        new_tail = UCTail(us.extend({path: new_paths}, tail_opts))

        engine.removeInput curr_tail, (err) ->
          throw err if err
          engine.addInput new_tail, (err) ->
            if err
              logger.error err
            else
              curr_tail = new_tail
              curr_paths_checksum = new_paths_checksum
           

  return {
    start : (callback) ->
      engine.start((err) ->
        return callback(err) if err
        _refreshInput()
        logger.info "engine started"
        interval_obj = setInterval(_refreshInput, engine_opts.config_refresh_interval )
        callback()
      )
    
    shutdown : (callback) ->
      if interval_obj
        clearInterval(interval_obj)
      engine.shutdown(callback)
  }