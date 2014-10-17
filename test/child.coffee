sys = require 'async'
fs = require 'fs'
async = require 'async'

process.on 'message', (message) ->
  console.log "recieve message"


chunk = [1...3000000]
tmp_file = '/var/tmp/aa.txt'
start = 0
end = 0
fs.open tmp_file, 'w', (err, fd) ->
  start = (new Date()).getTime()
  console.log "start"
  async.eachSeries chunk
  , (data, callback) ->
      head = new Buffer("this is line\n")
      fs.write fd, head, 0, head.length, null,  (err) ->
        callback()
  , (err) ->
      fs.close fd, (close_err) ->
        end = (new Date()).getTime()
        console.log "done: #{end - start}"
      
   