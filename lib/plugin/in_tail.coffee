util = require '../util'
report = require '../report'
Tail = require('tail-forever').Tail
xregexp = require('xregexp').XRegExp
glob = require 'glob'
path = require 'path'
us = require 'underscore'
dirty = require 'dirty'
fs = require 'fs'
moment = require 'moment'
os = require 'os'

module.exports = (config) ->
  ###
    path
    pattern: <time> and <value> two group capture
    posfile
    timeFormat: optional
  ###
  tails = {}
  posdb = null
  flush_interval = null

  # inodes save the the set of inode of last flush
  # we can use this to check if new found files
  # is just a rename old file, e.g web.log name to web.log.1
  # we shouldn't treat web.log.1 as a new file as from start
  # , instead we should read if from end
  inodes = []

  plugin_report = null

  unwatch = (p) ->
    mem = tails[p].unwatch()
    delete tails[p] 
    return mem
  
  globFiles = (_path) ->
    glob.sync(_path).map((f) -> 
      path.resolve(f)
    )

  flushTails =  (listener) ->
    curr_paths = us.keys(tails)
    target_paths = globFiles(config.path)
    to_add = us.difference(target_paths, curr_paths) 
    to_remove = us.difference(curr_paths, target_paths)
    target_inodes = us.reduce(
      target_paths, 
      (mem,p) -> 
        mem[p] = fs.statSync(p).ino
        return mem
      ,
      {}
      )
    
    for f in to_add
      inode = target_inodes[f]
      ## null start indicate read file from end
      start = if us.contains(inodes, inode) then null else 0
      tails[f] = new Tail(f, {start: start})
      tails[f].on('line', listener)

    inodes = us.values(target_inodes)
    if inodes.length  == 0
      plugin_report('problem', "no files was found")
    else
      plugin_report('ok')
    for f in to_remove
      unwatch(f)


  return {
    start : (emit, callback) ->
      logger.info "tail plugin starting..."

      parseTime =  (string_time) ->
        m = moment(string_time, config.timeFormat)
        return m.toDate() if m.isValid()

      online = (line) -> 
        x = xregexp(config.pattern)
        m = xregexp.exec(line, x)

        return if not m
        value = parseFloat(m.value || '1')
        return if isNaN(value)

        timestamp = (m.time and parseTime(m.time) ) || new Date()
        util.emitTSD(emit, config.monitor, value, timestamp, {host: os.hostname()})

      plugin_report = report.PluginReport(emit, config.monitor)
      posdb = dirty(config.posfile) 

      posdb.on('load', () ->
        for f in globFiles(config.path)
          inodes.push(fs.statSync(f).ino)
          mem = posdb.get(f)
          if mem
            tail_options = {start: mem.pos, inode: mem.inode}
          else
            tail_options = {}
          tails[f] = new Tail(f, tail_options)
          tails[f].on('line', (line) ->
            setImmediate( online, line )
          )

        if inodes.length  == 0
          plugin_report('problem', "no files was found")
        else
          plugin_report('ok')
        flush_interval = setInterval(flushTails, 1000, online, {start: 0}) 
        callback()
      )

    shutdown : (callback) ->
      logger.info "tail plugin shutdonw..."
      if flush_interval
        clearInterval(flush_interval)
      for _path, tail of tails 
        posdb.set(_path, unwatch(_path)) 
      callback()
  }