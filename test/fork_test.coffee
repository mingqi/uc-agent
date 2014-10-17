supervisor = require '../lib/supervisor'
script  = "./child.js"
args = null
sup = supervisor.Supervisor(script, args, 1000)
sup.run (err) ->
  console.log err

