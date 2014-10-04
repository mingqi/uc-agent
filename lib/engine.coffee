Engine = require './engine'
plugin = require './plugin'
upload = require './plugin/out_upload'
us = require 'underscore'
stdout = require './plugin/out_stdout'
hoconfig = require 'hoconfig-js'
path = require 'path'
glob = require 'glob'
fs = require 'fs'
md5 = require 'MD5'
async = require 'async'
VError = require('verror')
logcola = require 'logcola'

_checksum = (paths) ->
  md5(paths.slice().sort().join(','))

module.exports = (configer, inputs, outputs, tail_opts) -> 

  curr_paths = []
  curr_paths_checksum = _checksum(curr_paths)
  curr_tail = null
  engine = logcola.engine()

  for input in inputs
    engine.addInput(input)

  for [match, output] in outputs
    engine.addOutput(match, output)

  _refreshInput = () ->
    configer (err, paths) ->
      if err
        logger.error err.stack
        return

      new_paths = paths
      new_paths_checksum =  _checksum(new_paths)

      if new_paths_checksum != curr_paths_checksum
        new_tail = logcola.plugins.tail
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
           

  return {
    start : (callback) ->
      engine.start((err) ->
        return callback(err) if err
        refreshInput()
        logger.info "engine started"
        setInterval(refreshInput, 2000)
        callback()
      )
    
    shutdown : (callback) ->
      engine.shutdown(callback)
  }