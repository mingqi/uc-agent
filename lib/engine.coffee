Engine = require './engine'
us = require 'underscore'
hoconfig = require 'hoconfig-js'
path = require 'path'
fs = require 'fs'
md5 = require 'MD5'
async = require 'async'
VError = require('verror')
logcola = require 'logcola'

_checksum = (paths) ->
  md5(paths.slice().sort().join(','))

###
engine_opts:
  - configer
  - inputs
  - outputs
  - config_refresh_second

tail_opts:
  - pos_file
  - refresh_interval_seconds
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
      if err
        logger.error err.stack
        return

      new_paths = paths
      new_paths_checksum =  _checksum(new_paths)

      if new_paths_checksum != curr_paths_checksum
        new_tail = logcola.plugins.Tail
          path: new_paths
          pos_file: tail_opts.pos_file
          refresh_interval_seconds: tail_opts.refresh_interval_seconds

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
        interval_obj = setInterval(_refreshInput, engine_opts.config_refresh_second * 1000)
        callback()
      )
    
    shutdown : (callback) ->
      if interval_obj
        clearInterval(interval_obj)
      engine.shutdown(callback)
  }