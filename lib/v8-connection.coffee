###
  lib/v8-connection.coffee
###

net        = require 'net'
util       = require 'util'
_          = require 'underscore'
{Protocol} = require '_debugger'

module.exports =
class V8connection
  
  constructor: (@ideView) ->
    @reqSeq = 1
    @reqCallbacks       = {}
    @breakCallbacks     = []
    @exceptionCallbacks = []
    @closeCallbacks     = []
    @endCallbacks       = []
    @connected          = no
    
  connect: (host, port, cb) ->
    protocol = new Protocol()
    protocol.onResponse = (res) => process.nextTick =>  
      if res.headers.Type is 'connect'
        console.log '\n------------------- v8 connect -------------------'
        @connected = yes
        cb()
      else 
        @response res
    @socket = net.connect {host, port}
    @socket.setEncoding "utf8"
    @socket.on "data", (data) => protocol.execute data
    @socket.on "close", (res) => for cb in @closeCallbacks then cb res
    @socket.on "end",   (res) => for cb in @endCallbacks   then cb res
    @socket.on "error", (err) => 
      @error 'network error', err.message
      if not @connected then cb err.message

  request: (command, args, cb) ->
    if not @connected then return
    if cb then @reqCallbacks[@reqSeq] = cb
    req = {type: 'request', seq: @reqSeq++, command}
    if args then req.arguments = args
    json = JSON.stringify req 
    @socket.write "Content-Length: " + 
                  Buffer.byteLength(json, "utf8") + 
                  "\r\n\r\n" + json
  
  response: (res) ->
    {type, request_seq, event, success, body} = res.body
    switch 
      when type is 'event' 
        switch event
          when 'break'     then for cb in @breakCallbacks     then cb body
          when 'exception' then for cb in @exceptionCallbacks then cb body
      when not success     then @error 'response error:', res
      when type is 'response'
        @reqCallbacks[request_seq]? body
        delete @reqCallbacks[request_seq]
      else @error 'unknown response:', res
        
  onBreak:     (cb) -> @breakCallbacks    .push cb
  onException: (cb) -> @exceptionCallbacks.push cb
  onClose:     (cb) -> @closeCallbacks    .push cb
  onEnd:       (cb) -> @endCallbacks      .push cb

  parseArgsByType: (argsIn, types, args = {}) ->
    for arg in argsIn
      type = typeof arg
      if type is 'function' then cb = arg
      else if type is 'object' and not types['object'] 
        _.extend args, arg
      else args[types[type] ? 'bad-type'] = arg
    {args, cb}

  step: ->
    pa = @parseArgsByType arguments, number: 'stepcount', string: 'stepaction'
    @request 'continue', pa.args, -> pa.cb? null
    
  setScriptBreakpoint: ->
    pa = @parseArgsByType arguments, 
      boolean: 'enable', number: 'line', string: 'target'
    , type: 'script'
    @request 'setbreakpoint', pa.args, (res) -> 
      if res.type isnt 'scriptName' 
        pa.cb? @error 'setbreakpoint result not scriptName', res
      else pa.cb? null, res
    
  changebreakpoint: (args) ->
    @request 'changebreakpoint', args, -> 
      pa.cb? null, null    
  
  clearbreakpoint: (breakpoint) ->
    @request 'clearbreakpoint', {breakpoint}
    
  getScriptBreakpoints: (cb) ->
    @request 'listbreakpoints', null, (res) -> cb? null, res
    
  resume: (cb) -> @request 'continue', null, -> cb? null
  
  error: (msg, args...) ->
    errObj = message: 'v8 interface error: ' + msg
    console.log 'node-ie:', errObj.message, args
    @ideView.destroy()
    @destroy()
    errObj

  destroy: -> 
    @request 'disconnect', null, =>
      @connected = no 
      @socket.end()
