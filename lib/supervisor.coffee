spawn = require('child_process').spawn
fork = require('child_process').fork
util = require './util'
running = require('is-running')

###
- script: child script
- args: arguments of child
- watch_time: the millisecond to watch child after fork it. If child exit in this watch_time
  will be treat failed to fork. 
- wait_time: 

###
exports.Supervisor = Supervisor = (script, args, options) ->  
  watch_time = options.watch_time
  restart_wait_time = options.restart_wait_time
  kill_wait_time = options.kill_wait_time

  env = process.env
  env.__supervisor_child = true;
  fork_opts = {
    cwd : process.cwd
    env : env
  }

  child = null
  can_restart = false

  forkChild = (is_first, callback) ->
    callback = (() -> ) if not callback
    child = fork(script, args, fork_opts)

    if is_first
      util.wait(100, watch_time
      , () ->
          not running(child.pid)     
      , (err, not_running) ->
          if not_running
            callback(new Error("child process quit in #{watch_time}"))
          else
            callback()
      )

    child.on('exit', (code, signal) ->
      return if not can_restart 
      setTimeout(() ->
        process.nextTick(forkChild)
      , restart_wait_time
      )
    )

  killChild =  (callback) ->
    util.kill(child.pid, kill_wait_time, callback )

  sendHeartbeat = () ->
    setInterval(() ->
      child.send('heartbeat') if child.connected
    , 500
    )
  
 
  return {
    run : (callback) ->
      forkChild(true, (err) ->
        if not err
          can_restart = true
          sendHeartbeat()
        callback(err)
      )

      process.on('SIGTERM', () ->
        can_restart = false
        killChild(() ->
          process.exit()        
        )
      )
      
      process.on('SIGINT', () ->
        can_restart = false
        killChild(() ->
          process.exit()
        )
      )
  }


###
if supervisor abort abnormally, e.g. kill -9, child should also quit.
supervisor will send heartbeat message to child every 0.5 seconds.
child can use this function to received heartbeat and child process
will quit if not recieved heartbeat over timetout
###
exports.checkHeartbeat = checkHeartbeat = (timeout) ->
  last_heartbeat = null
  process.on('message', (msg) ->
    return if msg != 'heartbeat' 
    last_heartbeat = util.systemTime()
  )

  setInterval(() ->
    return if not last_heartbeat
    if (util.systemTime() - last_heartbeat ) > timeout
      logger.warn "too long not receive parent heartbeat, quit."
      process.exit()
  , 500
  )