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
    @connectPending     = yes
    
  connect: (host, port, cb) ->
    protocol = new Protocol()
    
    protocol.onResponse = (res) => process.nextTick =>  
      if res.headers.Type is 'connect'
        # console.log '\n------------------- v8 connect -------------------'
        @connected = yes
        @connectPending = no
        @ideView.showConnected yes
        cb null, res
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
    ok = @connected or @connectPending
    
    # console.log 'request', command, ok, @reqSeq, args
    
    if not ok then return

    @reqCallbacks[@reqSeq] = cb
    req = {type: 'request', seq: @reqSeq, command}
    if args then req.arguments = args
    try
      json = JSON.stringify req 
    catch
      debugger
    @socket.write "Content-Length: " + 
                  Buffer.byteLength(json, "utf8") + 
                  "\r\n\r\n" + json
    @reqSeq++
  
  response: (res) ->
    {type, event, command, request_seq, success, message, body} = res.body
    # console.log 'response', (command ? event), request_seq, res
    switch type
      
      when 'event'
        switch event
          when 'break'     then for cb in @breakCallbacks then cb body
          when 'exception' then for cb in @exceptionCallbacks then cb body
          
      when 'response'
        if (cb = @reqCallbacks[request_seq])
          ignoreErr = cb (if not success then [message, null] else [null, res.body])...
        delete @reqCallbacks[request_seq]
        if not success and ignoreErr isnt true
          @error 'response error:', res
        
      else @error 'unknown response:', res
        
  onBreak:     (cb) -> @breakCallbacks    .push cb
  onException: (cb) -> @exceptionCallbacks.push cb
  onClose:     (cb) -> @closeCallbacks    .push cb
  onEnd:       (cb) -> @endCallbacks      .push cb

  version: (cb) ->
    @request 'version', {}, (err, res) -> 
      {V8Version} = res.body
      {running}   = res
      cb null, {V8Version, running} 
    
  step: (stepaction, cb, stepcount=1) ->
    args = {stepaction, stepcount}
    @request 'continue', args, -> cb? null
    
  setScriptBreakpoint: (breakpoint, cb) ->
    opts = breakpoint.getData()
    args = _.extend {type: 'script', target: opts.file}, opts
    @request 'setbreakpoint', args, (err, res) -> cb? null, res
    
  changebreakpoint: (args, cb) ->
    @request 'changebreakpoint', args, -> cb? null, null    
  
  clearbreakpoint: (breakpoint) ->
    @request 'clearbreakpoint', {breakpoint}, -> yes
    
  getScriptBreakpoints: (cb) ->
    @request 'listbreakpoints', null, (err, res) -> cb? err, res
    
  setExceptionBreak: (type, enabled) ->
    @request 'setexceptionbreak', {type, enabled}
    
  getScriptSrc: (scriptId, filter, cb) ->
    args =
      types: 7
      ids: [scriptId]
      includeSource: yes
      filter: filter
    @request 'scripts', args, (err, res) -> cb? err, res.body
  
  suspend: (cb) -> @request 'suspend',  null, -> cb? null
  resume:  (cb) -> @request 'continue', null, -> cb? null
  
  frame: (number, cb) -> 
    @request 'frame', {number}, (err, res) -> 
      cb err, res
      if err is 'No frames' then return true
      
  getStack: (cb) ->
    @request 'backtrace', {}, (err, res) -> 
      cb err, res
      if err is 'No frames' then return true
      
  getExecPosition: (number, cb) ->
    @frame number, (err, res) =>
      if err then cb err; return
      {script, line, column} = res.body
      break for ref in res.refs when ref.handle is script.ref
      cb null, {file: ref.name, line, column}
      
  evalExpression: (expr, cb) ->
    expr = '(' + expr + ')'
    args =
      expression: expr
      # frame:
      # global:
      # disable_break:
      # additional_context:
    @request 'evaluate', args, (err, res) -> 
      console.log 'evalExpression', '"' + expr + '"', {err, res}
      cb? err, res?.body    
      yes
      
  error: (msg, args...) ->
    if args[0]?.indexOf?('ECONNRESET') > -1 or
       args[1]?.indexOf?('ECONNRESET') > -1
      console.log 'node-ide: lost connection to target'
      @connected = no
      @ideView.showConnected no
      for cb in @closeCallbacks then cb res
      return message: 'node-ide: lost connection to target'
      
    if (bodyMsg = args[0]?.body?.message)
      msg += ' ' + bodyMsg.toUpperCase() + ', '
    errObj = message: 'v8 interface error: ' + msg
    console.log 'node-ie:', errObj.message, args
    @destroy()
    errObj

  destroy: ->
    @request 'disconnect', null, =>
      @connected = no 
      @socket.end()
      @ideView.showConnected no