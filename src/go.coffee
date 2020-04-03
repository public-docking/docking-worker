#!/usr/bin/env iced
module = @
require "fy"
fs        = require "fs"
{exec}    = require "child_process"
Websocket_wrap = require "ws_wrap"
config    = require "./config"
{launch}  = require "./launch"
Ws_request_service  = require "./ws_request_service"
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
      data        : "download error"
    }
    return
  
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
  
  if err
    perr err
    ws.write {
      switch      : "docking_job_submit"
      request_uid : data.request_uid
      error       : "some error"
    }
  ws.write {
    switch      : "docking_job_submit"
    request_uid : data.request_uid
    
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
      ws.write switch : "ping"
      await setTimeout defer(), 1000
  
# 
@stop = ()->
  ws.close()

if !global.__IS_TEST
  module.start()
