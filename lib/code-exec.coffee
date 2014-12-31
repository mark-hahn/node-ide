###
   lib/code-exec.coffee
###

_            = require 'underscore'
fs           = require 'fs'
Breakpoint   = require './breakpoint'
V8connection = require './v8-connection'

module.exports =
class CodeExec
  
  constructor: (@ideView) ->
    {state, @breakpointMgr} = @ideView
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
            if not err then @codeDisplay.showCurExecLine execPosition
  
  showPaused: (execPosition)->
    {file, line, column} = execPosition
    @ideView.showRunPause no
    if not fs.existsSync file
      console.log 'node-ide: file without source:', file
      @codeDisplay.removeCurExecLine()
      @step 'out'
      return
    @codeDisplay.showAll {file, line, column}
      
  run: ->
    @codeDisplay.removeCurExecLine()
    @connection?.resume =>
      @ideView.showRunPause yes
      
  pause: ->
    @connection?.suspend => 
      @connection.getExecPosition 0, (err, execPosition) =>
        if not err then @showPaused execPosition
    
  step: (type) ->
    @connection?.step type, =>
      @ideView.showRunPause yes
      
  addBreakpoint: (breakpoint, cb) ->
    @connection?.setScriptBreakpoint breakpoint, (err, res) =>
      if err then cb? err; return
      {breakpoint: v8Id, actual_locations: actualLocations} = res.body
      added = no
      for actualLocation in actualLocations
        line   = actualLocation.line
        column = actualLocation.column
        added = yes
        break
      cb? null, {v8Id, line, column, added}

  changeBreakpoint: (breakpoint) ->
    {v8Id: breakpoint, enabled, ignoreCount, condition} = breakpoint
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
        
  setCaughtExc:   (set) -> @connection.setExceptionBreak 'all',       set
  setUncaughtExc: (set) -> @connection.setExceptionBreak 'uncaught',  set

  setUpEvents: ->
    @connection?.onBreak (body) =>
      {script, sourceLine: line, sourceColumn: column} = body
      file = script.name 
      @showPaused {file, line, column}
      
  destroy: ->
    @codeDisplay?.removeCurExecLine()
    @connection?.destroy()
    @ideView.showConnected no

