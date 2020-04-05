#!/usr/bin/env iced
module = @
require "fy"
fs        = require "fs"
os        = require "os"
{
  exec
  execSync
}    = require "child_process"
Websocket_wrap = require "ws_wrap"
config    = require "./config"
{
  launch
  check_number
  default_param
}  = require "./launch"
Ws_request_service  = require "./ws_request_service"

free_slot = os.cpus().length


execSync "mkdir -p #{config.path_to_download}"
execSync "mkdir -p #{config.path_to_job}"
# ###################################################################################################

download_map = new Map
ws = null
wsrs = null

dl = (path, on_end)->
  opt = {
    switch : "download"
    path
  }
  if -1 != path.indexOf ".."
    return on_end new Error "security reject path=#{path}"
  
  dst_path = "#{config.path_to_download}/#{path}"
  await wsrs.request opt, defer(err, res_dl);           return on_end err if err
  await fs.writeFile dst_path, res_dl.data, defer(err); return on_end err if err
  download_map.set path, dst_path
  
  on_end()


docking_job_dl_process = (data, on_end)->
  if !download_map.has data.receptor
    await dl data.receptor, defer(err); return on_end err if err
  
  if !download_map.has data.ligand
    await dl data.ligand, defer(err); return on_end err if err
  
  on_end()
# ###################################################################################################

# moved doe istanbul/coffeecoverage bug
docking_job = (data)->
  await docking_job_dl_process data, defer(err)
  if err
    perr err
    ws.write {
      switch      : data.switch
      request_uid : data.request_uid
      task_id     : data.task_id
      error       : "download error"
      free_slot
    }
    return
  
  if check_number data.exhaustiveness
    slot_size = +data.exhaustiveness
  else
    slot_size = +default_param.exhaustiveness
  
  free_slot -= slot_size
  
  ws.write {
    switch      : data.switch
    request_uid : data.request_uid
    free_slot
  }
  
  
  opt = {
    task_id       : data.task_id
    receptor_path : download_map.get data.receptor
    ligand_path   : download_map.get data.ligand
    
    center_x      : data.center_x
    center_y      : data.center_y
    center_z      : data.center_z
    
    size_x        : data.size_x
    size_y        : data.size_y
    size_z        : data.size_z
    
    exhaustiveness: data.exhaustiveness
  }
  await launch opt, defer(err, res)
  puts "launch done"
  
  free_slot += slot_size
  puts "free_slot", free_slot
  if err
    perr err
    ws.write {
      switch      : "docking_job_submit"
      request_uid : data.request_uid
      task_id     : data.task_id
      free_slot
      error       : "some error"
    }
    return
  
  ws.write {
    switch      : "docking_job_submit"
    request_uid : data.request_uid
    task_id     : data.task_id
    free_slot
    
    res_stderr  : res.res_stderr.toString()
    res_stdout  : res.res_stdout.toString()
    res_log     : res.res_log.toString()
    result      : res.result.toString()
  }

# ###################################################################################################
@start = ()->
  ws = new Websocket_wrap config.ws_master
  wsrs = new Ws_request_service ws
  
  ws.on "data", (data)->
    switch data.switch
      when "docking_job"
        docking_job data
    
    return
  
  do ()->
    while !ws._need_close
      ws.write {
        switch : "ping"
        free_slot
      }
      await setTimeout defer(), 1000
  
# 
@stop = ()->
  ws.close()

if !global.__IS_TEST
  module.start()
