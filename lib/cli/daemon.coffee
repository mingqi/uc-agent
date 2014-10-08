program = require 'commander'
Deamonize = require '../daemonize'

args = process.argv[2..]
action = args.shift()

daemon = Deamonize({
  script: require.resolve('./uc-agent.js')
  args: args
  pidFile: process.env.MA_AGENT_PID ||  '/var/run/uc-agent/uc-agent.pid'
  outFile: "/var/log/uc-agent.log"
  errFile: "/var/log/uc-agent.log"
  stopTimeout: 3000
  startTimeout: 3000
})


help = () ->
  console.log "usage: uc-agent <start|stop|restart> [args] "
  process.exit(1)
  

if not action
  help()

switch action
  when 'start'
    daemon.start((err) ->
      console.log "[error] #{err.message}" if err
      exit_code = if err then 1 else 0
      process.exit(exit_code)
    )
  when 'stop'
    daemon.stop((err) ->
      exit_code = if err then 1 else 0
      process.exit(exit_code)
    )
 
  when 'restart' 
    daemon.restart((err) ->
      exit_code = if err then 1 else 0
      process.exit(exit_code)
    )

  else
    help()
 
   
 