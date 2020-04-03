module = @
require "fy"
fs = require "fs"
WebSocket = require "ws"

@result_callback = ()->

ws = null
@start = ()->
  ws = new WebSocket.Server port : 7777
  ws.on "connection", (con)->
    # small dumb server
    con.on "message", (msg)->
      try
        data = JSON.parse msg
      catch err
        return perr err
      
      switch data.switch
        when "ping"
          con.send JSON.stringify {
            switch : "pong"
          }
        
        when "download"
          if data.path in ["receptor.pdbqt", "ligand.pdbqt"]
            con.send JSON.stringify {
              switch      : data.switch
              request_uid : data.request_uid
              data        : fs.readFileSync "./test/test_files/#{data.path}", "utf-8"
            }
        
        when "docking_job"
          p "ACK received"
        
        when "docking_job_submit"
          con.send JSON.stringify {
            switch      : data.switch
            request_uid : data.request_uid
            data        : "ok"
          }
          module.result_callback data
      
      return
    
    # send sample task
    con.send JSON.stringify {
      switch        : "docking_job"
      
      task_id       : "deadbeefaaa"
      receptor      : "receptor.pdbqt"
      ligand        : "ligand.pdbqt"
      
      center_x      : 11
      center_y      : 90.5
      center_z      : 57.5
      
      size_x        : 22
      size_y        : 24
      size_z        : 28
      
      exhaustiveness: 1
      # clean_up      : false # for debug
      clean_up      : true
    }

@stop = ()->
  ws.close()
