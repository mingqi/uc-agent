spawn = require('child_process').spawn
fs = require 'fs'
running = require('is-running')
util = require './util'
async = require 'async'

### options:
  script
  args
  pidFile
  outFile
  errFile 
  stopTimeout
###  

module.exports  = (options) ->
  script = options.script
  args = options.args || []
  pidFile = options.pidFile
  startTimeout = parseInt(options.startTimeout)
  stopTimeout = parseInt(options.stopTimeout)
  outFile = options.outFile
  errFile = options.errFile

  if not pidFile
    throw new Error("pidFile argument not given")

  readPid = () ->
    if not fs.existsSync(pidFile) 
      return null
    try
      pid = fs.readFileSync(pidFile)
      if pid
        return parseInt(pid)
    catch e
      return null

  writePid = (pid) ->
    fs.writeFileSync(pidFile, pid)
   
  return {

    start : (callback) ->
      pid = readPid()
      if pid and running(pid)
        return callback()

      opt = opt || {};
      env = opt.env || process.env;

      out = if outFile then fs.openSync(outFile, 'a') else 'ignore';
      err = if errFile then fs.openSync(errFile, 'a') else 'ignore';
      cp_opt = {
        detached: true
        env : options.env || process.env
        cwd : options.cwd || process.cwd     
        stdio: ['ignore', out, err],
      }
      child = spawn(process.execPath, [script].concat(args), cp_opt)
      child.unref();

      util.wait(100, startTimeout, () ->
        not running(child.pid)
      , (err, not_running) ->
        if not_running
          return callback(new Error("#{script} failure startup which quit within #{startTimeout} millSeconds"))
        else
          try
            writePid(child.pid)
          catch e
            util.kill(child.pid, stopTimeout, () ->
              process.exit(2)
            )
            return callback(new Error("failed to write pid file, #{pidFile}: #{e.message}"))
          callback()
      )

    stop : (callback) ->
      pid = readPid()
      if pid and running(pid)
        util.kill(pid, stopTimeout, (err) ->
          if not err
            fs.unlinkSync(pidFile)  
          callback(err)
        )
      else
        callback()

    restart : (callback) ->
      this.stop((err) =>
        if err
          callback(err)
        this.start(callback)
      )
  }