Agent = require '../agent'
config = require '../config'
hoconfig = require 'hoconfig-js'
stdout = require '../plugin/out_stdout'
upload = require '../plugin/out_upload'
us = require 'underscore'
log4js = require 'log4js'
global.logger = log4js.getLogger()

args = process.argv[2..]
if args.length !=2
  console.error "useage: agent <agent-config-file> <plguin-config-file>"
  process.exit(1)

pluginconfig = args[1]

agentconfig = hoconfig(args[0])
options = {
  remote_host : 'localhost'
  remote_port : 9090
  buffer_size : 1000
  buffer_flush : 3
  uri : '/tsd'
}

out_upload = upload(us.extend(options, agentconfig))

agent = Agent(
  ((cb) -> 
    config.local(pluginconfig, cb)
    # config.remote('localhost', 9090, cb)
  ), 
  [], 
  [['tsd', stdout()]
  ['tsd', out_upload]], 
  options)

agent.start (err) ->
  console.log err


