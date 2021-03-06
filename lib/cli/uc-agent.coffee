program = require 'commander'
path = require 'path'
fs = require 'fs'
us = require 'underscore'
log4js = require 'log4js'
logcola = require 'logcola'
hoconfig = require 'hoconfig-js'
uuid = require 'uuid'
extend = require 'extend'

Engine = require '../engine'
config = require '../config'
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

_readAgentId = (agent_id_file) ->
  if not fs.existsSync agent_id_file
    fs.writeFileSync( agent_id_file, uuid.v4() )
  fs.readFileSync(agent_id_file, {encoding: "utf8"}).trim()
  

_runEngine = (options, callback) -> 
  remote_config = (callback) ->
    config.remote({
      ssl: options.remote.ssl
      host: options.remote.host, 
      port: options.remote.port, 
      license_key: options.license_key
      agent_id: options.agent_id
      }, callback)

  remote_backup_config = (callback) ->
    config.backup(
      remote_config,
      path.join(options.run_directory, 'remote_backup_config.json')
      callback
    )

  local = (callback) ->
    config.local(options.log_config_file, callback)

  merged_config = (callback) ->
    config.merge(remote_backup_config, local, callback)
  
  input_plugins = [
    {
      type: 'uc_status'
      interval: options.status_interval
      agent_id: options.agent_id
    }
  ]  

  output_plugins = [
    us.extend({
      match: 'log'
      type: 'uc_upload'
      host: options.remote.host
      port: options.remote.port
      ssl: options.remote.ssl
      uri: '/log'
      license_key: options.license_key
    }, options.buffer),   
    {
      match: 'status'
      type: 'uc_upload'
      host: options.remote.host
      port: options.remote.port
      ssl: options.remote.ssl
      uri: '/status'
      license_key: options.license_key
      buffer_type: 'memory'
      buffer_flush: 1
      buffer_size: 1000
      retry_times: 1
      retry_interval: 1000
      buffer_queue_size: 1
      concurrency: 1
    }
  ]

  if options.debug
    output_plugins.push {match: 'status', type: 'uc_debug'}
    output_plugins.push {match: 'log', type: 'uc_debug'}

  logcola.plugin.setPluginPath( path.join( __dirname, '../plugin' ) )

  engine = Engine(
    {
      configer: merged_config 
      inputs:  input_plugins.map logcola.plugin
      outputs : output_plugins.map (c) -> [c.match, logcola.plugin(c)]
      config_refresh_interval: options.config_refresh_interval
    },
    options.tail
  )

  engine.start (err) ->
    return callback(err) if err
    logger.info "logcola engine started"
    callback(null, engine)   
  

_worker = (options) ->
    
  ## this is child run
  _runEngine options, (err, engine) ->
    if err
      logger.error err.stack
      process.exit(1) 

    hb_interval =  null

    _quit = () ->
      logger.warn "child / worker process are cleanup and quit..."
      clearInterval hb_interval if hb_interval
      engine.shutdown (err) ->
        console.log "engine shutdown done"
        console.log err.stack if err
        logger.error err.stack if err
        process.exit()

      setTimeout(() ->
        logger.warn "child / worker not completed cleanup in #{options.worker_cleanup_timeout} millsenconds, force quit"
        process.exit()
      , options.worker_cleanup_timeout)      
          
    hb_interval = supervisor.checkParentPID(_quit)

    process.on 'SIGTERM', () ->
      logger.warn "uc-agent recieve SIGTERM signal"
      _quit()

     process.on 'SIGINT', () ->
      logger.warn "uc-agent recieve SIGINT signal"
      _quit()

    process.on 'uncaughtException', (err) ->
      logger.error "uc-agent got uncaughtException"
      logger.error err.stack
      console.err err.stack
      _quit()
        

_supervisord = (options) ->
  script = process.argv[1]
  args = process.argv[2..]
  sup = supervisor.Supervisor(script, args, options.supervisor)
  sup.run((err) ->
    if err
      console.log "failed to start uc-agent: #{err.message}"   
      process.exit(1)
  )


main = () ->
  program
    .version(version)
    .option('-c, --config [path]', 'config file')
    .option('-s, --supervisord', 'use supervisord mode')
    .parse(process.argv)

  options = 
    remote:
      host : 'agent.uclogs.com'
      port : 443
      ssl : true
    config_refresh_interval: 30000 # 30 seconds
    status_interval : 10000 # 10 seconds
    debug : false
    run_directory : '/var/uc-agent'
    log_config_file : '/etc/uc-agent/log_files.conf'

    tail : 
      pos_file: '/var/uc-agent/posdb'
      refresh_interval: 10000
      save_posotion_interval: 10000
      max_size: 52428800
      max_line_size: 5000
      buffer_size: 0
      encoding : 'auto'

    supervisor: 
      watch_time: 3000
      restart_wait_time: 1000
      kill_wait_time: 5000

    logging : 
      log_level : 'info'
      log_file : '/var/log/uc-agent.log'
      log_file_size : 20971520 # 10m
      log_file_count : 5
    
    buffer : 
      buffer_type : 'file'
      buffer_path : '/var/cache/uc-agent/log'
      buffer_flush : 30000
      buffer_size : 1048576
      retry_times : 30
      retry_interval : 60000
      buffer_queue_size : 200
      concurrency : 3

    worker_cleanup_timeout : 5000



  extend options, hoconfig(program.config or '/etc/uc-agent/uc-agent.conf')
  # console.log "uc-agent's configuration is #{JSON.stringify(options, null, 4)}"

  license_key_file = path.join options.run_directory, 'license_key'
  agant_id_file = path.join options.run_directory, 'agent_id'

  try
    license_key = _readLicenseKey(license_key_file)
  catch e
    console.log "license key can't be read correctly, please run '/opt/uc-agent/bin/license-key' to setup first: #{e.message}"
    process.exit(1)
  
  options.license_key = license_key
  options.agent_id = _readAgentId(agant_id_file)


  logging_opts = options.logging
  ## init logger
  log4js.setGlobalLogLevel(logging_opts.log_level || 'info')
  if logging_opts.log_file == 'console'
    log4js.addAppender(log4js.appenders.console() );
  else
    maxSize = 10 * 1024 * 1024 #10m
    if logging_opts.log_file_size
      maxSize = logging_opts.log_file_size

    maxFiles = 5
    if logging_opts.log_file_count
      maxFiles = parseInt(logging_opts.log_file_count)

    log4js.addAppender(log4js.appenders.file(logging_opts.log_file, null, maxSize, maxFiles));


  if program.supervisord and not process.env.__supervisor_child
    _supervisord(options)
  else
    _worker(options)

main()