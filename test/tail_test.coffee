logcola = require 'logcola'
log4js = require 'log4js'

global.logger = log4js.getLogger()

uc_tail = require '../lib/plugin/uc_tail'

tail = uc_tail
  path: '/var/tmp/1.log'
  pos_file: '/var/tmp/pos'
  refresh_interval_seconds: 1

engine = logcola.Engine()
engine.addInput tail
engine.addOutput 'log',logcola.plugins.Stdout()

engine.start()