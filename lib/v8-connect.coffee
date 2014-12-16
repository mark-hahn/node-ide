###
  lib/v8connect.coffee
###

net        = require 'net'
util       = require 'util'
{Protocol} = require '_debugger'

error = (msg, args...) ->
  errObj = message: 'v8 interface error: ' + msg
                  
  console.log 'node-ie:', errObj.message, args
  errObj
  
module.exports =
class V8connect
  constructor: (host, port, cb) ->
    @reqSeq = 1
    @reqCallbacks = {}
    @breakCallbacks = []
    @exceptionCallbacks = []
    
    protocol = new Protocol()
    protocol.onResponse = (res) => process.nextTick =>  
      if res.headers.Type is 'connect'
        console.log '\n------------------- v8 connect -------------------'
        cb()
      else @response res
        
    @socket = net.connect {host, port}
    @socket.setEncoding "utf8"
    @socket.on "data",     (data) => protocol.execute data
    @socket.on "error",     (err) -> error 'network error', err.message
    @socket.on "close", (args...) -> error 'network close', args
    @socket.on "end",   (args...) -> error 'network end',   args

  request: (command, args, cb) ->
    @reqCallbacks[@reqSeq] = cb
    req = {type: 'request', seq: @reqSeq++, command}
    if args then req.arguments = args
    json = JSON.stringify req 
    @socket.write "Content-Length: " + Buffer.byteLength(json, "utf8") + "\r\n\r\n" + json
  
  response: (res) ->
    {type, request_seq, event, success, body} = res.body
    switch 
      when type is 'event' 
        switch event
          when 'break'     then for cb in @breakCallbacks     then cb body
          when 'exception' then for cb in @exceptionCallbacks then cb body
      when not success     then error 'response error:', res
      when type is 'response'
        @reqCallbacks[request_seq] body
        delete @reqCallbacks[request_seq]
      else error 'unknown response:', res
        
  onBreak:     (cb) -> @breakCallbacks    .push cb
  onException: (cb) -> @exceptionCallbacks.push cb

  parseArgs: (boolNumStr, argsIn, args = {}) ->
    for arg in argsIn
      switch typeof arg
        when 'boolean'  then args[boolNumStr[0]] = arg
        when 'number'   then args[boolNumStr[1]] = arg
        when 'string'   then args[boolNumStr[2]] = arg
        when 'function' then cb = arg
    {args, cb}

  resume: (cb) -> @request 'continue', null, -> cb? null
  
  step: ->
    pa = @parseArgs ['', 'stepcount', 'stepaction'], arguments
    @request 'continue', pa.args, -> pa.cb? null
    
  getScriptBreakpoints: (cb) ->
    @request 'listbreakpoints', null, (res) -> cb? res
    
    
  #   
  # funcBrkArgs: (args, res) ->
  #   for arg in args
  #     switch typeof arg
  #       when 'boolean' then res.enabled     = arg
  #       when 'number'  then res.ignoreCount = arg
  #       when 'string'  then res.condition   = arg
  #   
  # funcBrkRes = (res, cb) ->
  #   if res.type isnt 'function' 
  #     cb error 'setbreakpoint function result type', res; return
  #   {breakpoint, actual_locations} = res
  #   {scriptId, line, columns} = actual_locations[0]
  #   cb null, {scriptId, line, columns}
  #   
  # setFuncOrHndlBreakpoint: (type, target, cb) ->
  #   args = @funcBrkArgs arguments[1..], {type, target}
  #   @request 'setbreakpoint', args, (res) -> funcBrkRes res, cb
  #   
  # setScriptBreakpoint: (type, target, cb) ->
  #   type = if func then 'function' else 'handle'
  #   
  #   target = func ? handle
  #   @request 'setbreakpoint ', 
  #     {target: , stepcount}, -> cb null
  #   
  # setFunctionBrkPnt: () ->
  #   switch type
  #     when 'function' then 
  #     
  #     