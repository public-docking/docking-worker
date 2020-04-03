class Ws_request_service
  ws : null
  request_uid : 0
  response_hash : {}
  interval  : 30000
  timeout   : 30000
  
  constructor : (@ws)->
    @response_hash = {}
    @ws.on "data", (data)=>
      # puts data
      if data.request_uid?
        if @response_hash[data.request_uid]?
          cb = @response_hash[data.request_uid].callback
          delete @response_hash[data.request_uid] if !data.continious_request
          delete data.request_uid
          cb null, data
        else
          perr "missing request_uid = #{data.request_uid}. Possible timeout"
      return
    
    setTimeout ()=>
      setInterval ()=>
        now = Date.now()
        for k,v of @response_hash
          if now - v.timestamp > @timeout
            delete @response_hash[k]
            perr "ws_request_service timeout"
            perr v.callback.toString()
            v.callback new Error "timeout"
        return
      , @interval
  
  request : (hash, handler)->
    hash.request_uid = @request_uid++
    @response_hash[hash.request_uid] =
      callback : handler
      timestamp : Date.now()
    @ws.write hash
    return
  
  send : @prototype.request

module.exports = Ws_request_service
