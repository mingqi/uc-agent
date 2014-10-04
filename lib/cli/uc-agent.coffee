program = require 'commander'
path = require 'path'
fs = require 'fs'
us = require 'underscore'
log4js = require 'log4js'

engine = require '../engine'
config = require '../config'
hoconfig = require 'hoconfig-js'
stdout = require '../plugin/out_stdout'
host = require '../plugin/in_host'
supervisor = require '../supervisor'
version = require '../version'
util = require '../util'

log4js.loadAppender('file');
log4js.loadAppender('console');

log4js.clearAppenders()
global.logger = log4js.getLogger('uc-agent')

_readLicenseKey = (license_key_file) ->
  if not fs.existsSync(license_key_file)
    throw new Error("license key #{license_key_file} doesn't exists!")

  content = fs.readFileSync(license_key_file, {encoding: "utf8"})
  return content.trim()
  

_runEngine = (options, callback) -> 
  remote_config = (callback) ->
    config.remote({
      host: options.remote_host, 
      port: options.remote_port, 
      license_key: options.license_key
      }, callback)

  remote_backup_config = (callback) ->
    config.backup
      remote_config,
      path.join(options.run_directory, 'remote_backup_config.json')
      callback

  # local = (callback) ->
  #   config.local('/etc/ma-agent/monitor.d', callback)

  # merged_config = (callback) ->
  #   config.merge(remote_backup_config, local, callback)
  
  input_plugins = []  
  agent = Agent(
    remote_backup_config,
    input_plugins, 
    [
      ['test', stdout()]
    ]
  )

  agent.start (err) ->
    return callback(err) if err
    callback(null, agent)   
  

_worker = (options) ->
  ## this is child run
  _runEngine , options, (err, agent) ->
    if err
      logger.error err.stack
      process.exit(1) 

    supervisor.checkHeartbeat(3000)

    process.on 'SIGTERM', () ->
      agent.shutdown (err) ->
        logger.error err.stack if err
        process.exit()

     process.on 'SIGINT', () ->
      agent.shutdown (err) ->
        logger.error err.stack if err
        process.exit()

    process.on 'uncaughtException', (err) ->
      logger.error err.stack, () ->
        agent.shutdown (err) ->
          logger.error err.stack if err
          process.exit()

      ## process will exit in 3 seconds
      setTimeout(() ->
        process.exit()
      , 3000 )
        

_supervisord = (options) ->
  script = process.argv[1]
  args = process.argv[2..]
  sup = supervisor.Supervisor(script, args, 3000)
  sup.run((err) ->
    if err
      console.log "failed to start ma-agent: #{err.message}"   
      process.exit(1)
  )


main = () ->
  program
    .version(version)
    .option('-c, --config [path]', 'config file')
    .option('-s, --supervisord', 'use supervisord mode')
    .parse(process.argv)

  options = 
    remote_host : 'agent.uclogs.com'
    remote_port : 443
    buffer_size : 10000
    buffer_flush : 30
    agent_report_interval: 30
    run_directory : '/var/run/uc-agent'
    tail : 
      pos_file: '/var/run/uc-agent/posdb'
      refresh_interval_seconds: 3
    supervisor: 
      watch_time: 3000
      restart_wait_time: 1000
      kill_wait_time: 3000

  us.extend options, hoconfig(program.config or '/etc/uc-agent.conf')
  license_key_file = path.join options.run_directory, 'license_key'

  try
    license_key = _readLicenseKey(license_key_file)
  catch e
    console.log "license key can't be read correctly, please run '/opt/uc-agent/bin/license_key' to setup first: #{e.message}"
    process.exit(1)
  
  options.license_key = license_key

  ## init logger
  logger.setLevel(options.log_level || 'info')
  if options.log_file == 'console'
    log4js.addAppender(log4js.appenders.console() );
  else
    maxSize = 10 * 1024 * 1024 #10m
    if options.log_file_size
      maxSize = util.parseHumaneSize(options.log_file_size)

    maxFiles = 5
    if options.log_file_count
      maxFiles = parseInt(options.log_file_count)

    log4js.addAppender(log4js.appenders.file(options.log_file, null, maxSize, maxFiles));


  if program.supervisord and not process.env.__supervisor_child
    _supervisord()
  else
    _worker(options)

main()