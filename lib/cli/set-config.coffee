us = require 'underscore'
fs = require 'fs'
command = require 'commander'
hoconfig = require 'hoconfig-js'

program = new command.Command("ma-agent-config")

program
  .option('-c, --config <config>', 'configurations file, default is /etc/ma-agent/ma-agent.conf', '/etc/ma-agent/ma-agent.conf')
  .option('-s, --set', 'set configuration')
  .usage('[options] <key=value ...>')
  .parse(process.argv)


config_file = program.config
if not fs.existsSync(config_file)
  console.log "config file '#{program.config}' is not exists"
  process.exit()

allowed = ['license_key']

key_values = {}
keys_replaced = {}
for arg in program.args
  m = /^([^ =]+)=([^ =]+)$/.exec(arg)
  if not m
    console.log "#{arg} is not match pattern <key=value>" 
    process.exit()

  if not us.contains(allowed, m[1]) 
    console.log "#{m[1]} is illegal key"
    process.exit()

  key_values[m[1]] = m[2]
  keys_replaced[m[1]] = false

content = fs.readFileSync(config_file, {encoding: "utf8"})
lines = content.split('\n')

updateLine = (line) ->
  for key, value of key_values
    r = new RegExp("^(\\s*#{key}\\s*=)(\\s*)(.*)$")
    m = r.exec(line)
    if m
      keys_replaced[key] = true
      return m[1] + m[2] + value

  return line

new_content = ""
new_lines =  for line in lines
  updateLine(line)

for key, replaced of keys_replaced
  if not replaced 
    new_lines.push "#{key} = #{key_values[key]}"

if program.set
  try
    fs.renameSync(config_file, config_file+'.bak')
    fs.writeFileSync(config_file, new_lines.join("\n"))
  catch e
    console.log e.message

