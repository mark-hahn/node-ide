###
   lib/code-exec.coffee
###

_            = require 'underscore'
fs           = require 'fs'
Breakpoint   = require './breakpoint'
V8connection = require './v8-connection'

dbgHost = '127.0.0.1'
dbgPort = 5858

module.exports =
class CodeExec
  
  constructor: (@ideView) ->
    {state, @breakpointMgr} = @ideView
    @breakpoints = state.breakpoints
    
    @ideView.showRunPause no
    # process.nextTick =>
    @connection = new V8connection @ideView
    @connection.connect dbgHost, dbgPort, (err) =>
      if err 
        @connection = null
        @ideView.showConnected no
        return
      @setUpConnectionEvents()
      @breakpointMgr.setCodeExec @
      @codeDisplay = @breakpointMgr.codeDisplay
      @ideView.showConnected yes
      @connection.version (err, res) =>
        {V8Version, running} = res
        @ideView.showRunPause running
        console.log 'node-ide: connected to:', dbgHost + ':' + dbgPort + ', V8:' + V8Version
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
    @codeDisplay.showCurExecLine {file, line, column}
      
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
      if err then cb? {}; return
      else
        {breakpoint: v8Id, actual_locations: actualLocations} = res.body
        for actualLocation in actualLocations
          line   = actualLocation.line
          column = actualLocation.column
          break
      cb? {v8Id, line, column}

  changeBreakpoint: (breakpoint) ->
    {v8Id: breakpoint, enabled, ignoreCount, condition} = breakpoint
    args = {breakpoint, enabled, ignoreCount, condition}
    @connection?.changebreakpoint args
                    
  clearbreakpoint: (breakpoint) ->
      @connection?.clearbreakpoint breakpoint.v8Id
    
  clearAllBreakpoints: ->
    @connection.getScriptBreakpoints (err, res) =>
      console.log res
      for breakpoint in res.body.breakpoints
        @connection?.clearbreakpoint breakpoint.number

  setUpConnectionEvents: ->
    @connection?.onBreak (body) =>
      {script, sourceLine: line, sourceColumn: column} = body
      file = script.name 
      @showPaused {file, line, column}
      
  destroy: ->
    @codeDisplay.removeCurExecLine()
    @connection?.destroy()
    @ideView.showConnected no
    console.log 'node-ide: disconnected'

