util = require '../lib/util'
log4js = require 'log4js'

global.logger = log4js.getLogger()

util.rest {"ssl":true,"host":"agent.uclogs.com","method":"GET","path":"/config/a3291edd-87ea-41d7-93d5-e707ab75543d","headers":{"licenseKey":"JGU1MiQOLWzlG898bJvQ"}}, (err, status, resp) ->
  console.log err
  console.log status
  console.log resp
