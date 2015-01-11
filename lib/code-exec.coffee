###
   lib/code-exec.coffee
###

_            = require 'underscore'
fs           = require 'fs'
path         = require 'path'
Breakpoint   = require './breakpoint'
V8connection = require './v8-connection'

module.exports =
class CodeExec
  
  constructor: (@ideView) ->
    {state, @breakpointMgr, @internalFileDir} = @ideView
    state.host ?= '127.0.0.1'
    state.port ?= 5858
    
    @ideView.showRunPause no
    @connection = new V8connection @ideView
    @connection.connect state.host, state.port, (err) =>
      if err 
        @connection = null
        @ideView.showConnected no
        return
      @setUpEvents()
      @breakpointMgr.setCodeExec @
      @codeDisplay = @breakpointMgr.codeDisplay
      @ideView.showConnected yes
      @connection.version (err, res) =>
        {V8Version, running} = res
        @ideView.showRunPause running
        console.log 'node-ide: connected to', 
                     state.host + ':' + state.port + ', V8:' + V8Version
        if not running
          @connection.getExecPosition 0, (err, execPosition) =>
            if not err then @paused execPosition
  
  noSource: (file) ->
    console.log 'node-ide: unable to get source for ', file
    @codeDisplay.removeCurExecLine()
    @step 'out'    
    
  getInternalPath: (file) ->
    ext  = path.extname file
    name = path.basename(file)[0...-ext.length]
    path.join @internalFileDir, '(' + name + ')' + ext
    
  paused: (execPosition, scriptId, exception)->
    {file, line, column} = execPosition
    fileIsInternal = not /\/|\\/.test file 
    if not atom.config.get('node-ide.enterInternalFiles') and 
        fileIsInternal and not exception
      @step 'out'
      return
    @ideView.showRunPause no
    if fileIsInternal then file = @getInternalPath file
    if not fs.existsSync file
      fileArg = (if not scriptId then file)
      @connection?.getScriptSrc scriptId, fileArg, (err, scripts) =>
        if err or scripts.length is 0 then @noSource file; return
        {source} = scripts[0]
        fs.writeFileSync file, source
        @breakpointMgr.showAll file, line, column
        return
      return
    @breakpointMgr.showAll file, line, column
    
    @connection.getStack (err, res) =>
      @frames = res.body.frames
      @refs   = res.refs
      @ideView.setStack @frames, @refs
    
  pause: ->
    @connection?.suspend => 
      @connection.getExecPosition 0, (err, execPosition) =>
        if not err then @paused execPosition
    
  running: ->
    @codeDisplay.removeCurExecLine()
    @codeDisplay.removeCurExecLine yes
    @ideView.showRunPause yes
    @ideView.breakpointPanel.update()
    @ideView.stackPanel.clear()
    
  run:         -> @connection?.resume     => @running()
  step: (type) -> @connection?.step type, => @running()
  
  addBreakpoint: (breakpoint, cb) ->
    oldLine = breakpoint.line
    @connection?.setScriptBreakpoint breakpoint, (err, res) =>
      if err then cb? err; return
      {breakpoint: v8Id, actual_locations: actualLocations} = res.body
      added = no
      for actualLocation in actualLocations
        line   = actualLocation.line
        column = actualLocation.column
        added = yes
        break
      if oldLine isnt line
        console.log 'node-ide warning: requested breakpoint moved, line:', 
                     oldLine+1, '->', line+1
      cb? null, {v8Id, line, column, added}

  changeBreakpoint: (breakpoint) ->
    {v8Id: breakpoint, enabled, ignoreCount, condition, active} = breakpoint
    enabled and= active
    args = {breakpoint, enabled, ignoreCount, condition}
    @connection?.changebreakpoint args
                    
  clearbreakpoint: (breakpoint) ->
    if breakpoint.v8Id
      @connection?.clearbreakpoint breakpoint.v8Id
    
  clearAllBreakpoints: ->
    @connection.getScriptBreakpoints (err, res) =>
      # console.log 'clearAllBreakpoints', res
      for breakpoint in res.body.breakpoints
        @connection?.clearbreakpoint breakpoint.number
        
  setCaughtExc:   (set) -> @connection?.setExceptionBreak 'all',       set
  setUncaughtExc: (set) -> @connection?.setExceptionBreak 'uncaught',  set

  getExecPosition: -> @execPosition

  setUpEvents: ->
    @connection?.onBreak (body) =>
      {script, sourceLine: line, sourceColumn: column} = body
      @paused {file:script.name, line, column}, script.id
      
    @connection?.onException (body) =>
      console.log 'exception:', body.exception.text, '\n', body
      {script, sourceLine: line, sourceColumn: column} = body
      @paused {file:script.name, line, column}, script.id, yes
      
  destroy: ->
    @codeDisplay?.removeCurExecLine()
    @connection?.destroy()
    @ideView.showConnected no

