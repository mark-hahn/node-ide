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
    @breakpoints = {}
    @ideView.showRunPause no
    process.nextTick =>
      @connection = new V8connection @ideView
      @connection.connect dbgHost, dbgPort, (err) =>
        if err 
          @connection = null
          @ideView.showConnected no
          return
        @setUpConnectionEvents()
        
        @ideView.showConnected yes
        @connection.version (err, res) =>
          {V8Version, running} = res
          @ideView.showRunPause running
          console.log 'node-ide: connected to:', dbgHost + ':' + dbgPort + ', V8:' + V8Version
          if not running
            @connection.getExecPosition 0, (err, execPosition) =>
              if not err then @codeDisplay.showCurExecLine execPosition
  
  setCodeDisplay: (@codeDisplay) ->
    
  isConnected: -> @connection?
            
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
      
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
    
  addBreakpoint: (file, lineIn) ->
    @connection?.setScriptBreakpoint file, lineIn, (err, res) =>
      if err then @destroy()
      else
        {breakpoint: id, actual_locations: actualLocations} = res.body
        for actualLocation in actualLocations
          line   = actualLocation.line
          column = actualLocation.column
          break
        if line
          for id, breakpoint of @breakpoints
            if breakpoint.file is file and
               breakpoint.line is line
              @clearbreakpoint id
              return
          breakpoint = new Breakpoint @, @codeDisplay, id, file, line, column
          @breakpoints[id] = breakpoint
          @codeDisplay.addBreakpoint breakpoint

  changeBreakpoint: (breakpoint) ->
    {id: breakpoint, enabled, ignoreCount, condition} = breakpoint
    args = {breakpoint, enabled, ignoreCount, condition}
    @connection?.changebreakpoint args
                    
  clearbreakpoint: (breakpointId) -> 
    @connection?.clearbreakpoint breakpointId
    @breakpoints[breakpointId].destroy()
    delete @breakpoints[breakpointId]

  toggleBreakpoint: (editor, line) ->
    file = @getPath editor
    for id, breakpoint of @breakpoints
      if breakpoint.file is file and
         breakpoint.line is line
        if breakpoint.enabled
          breakpoint.setEnabled no
        else
          @clearbreakpoint breakpoint.id
        return
    @addBreakpoint file, line
    
  setUpConnectionEvents: ->
    @connection?.onBreak (body) =>
      {script, sourceLine: line, sourceColumn: column} = body
      file = script.name 
      @showPaused {file, line, column}
      
  destroy: ->
    for id of @breakpoints then @clearbreakpoint id
    @connection?.destroy()
    @ideView.showConnected no
    console.log 'node-ide: disconnected'

