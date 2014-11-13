us = require 'underscore'
fs = require 'fs'
command = require 'commander'

LICENSE_KEY_FILE = '/var/uc-agent/license_key'
program = new command.Command("uc-agent-license-key")

program
  .option('-s, --set [license key]', 'set license key')
  .parse(process.argv)

checkLicenseKey = () ->
  if not fs.existsSync(LICENSE_KEY_FILE)
    console.log "file #{LICENSE_KEY_FILE} is not exists"
    process.exit()

  content = fs.readFileSync(LICENSE_KEY_FILE,{encoding: "utf8"})
  console.log content.trim()   

setLicenseKey =  (license_key) ->
  try
    if not fs.existsSync('/var/uc-agent')
      fs.mkdirSync('/var/uc-agent')
    fs.writeFileSync(LICENSE_KEY_FILE, license_key, {mode: 256}) 
    console.log "successfully set license_key #{license_key}"
  catch e
    console.log "failure to set license_key: #{e.message}" 
  


if not program.set
  checkLicenseKey()
else
  setLicenseKey(program.set) 
