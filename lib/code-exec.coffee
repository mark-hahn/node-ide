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
    @running = no
    process.nextTick =>
      @connection = new V8connection @
      @connection.connect dbgHost, dbgPort, (err) =>
        if err 
          @connection = null
          return
        @setUpConnectionEvents()
        
        @connection.version (err, res) =>
          {V8Version, @running} = res
          console.log 'node-ide: connected to V8 version:', {V8Version, @running}
          @ideView.showRunPause @running
          if not @running
            @getShowExecPosition()
            return
            
          @connection.suspend => 
            @running = no
            @ideView.showRunPause @running
            @getShowExecPosition()
  
  setCodeDisplay: (@codeDisplay) ->
    
  isConnected: -> @connection?
            
  addBreakpoint: (file, line) ->
    setScriptBreakpoint file, line, {}, cb (err, res) ->
      if err then @destroy()
      else
        {breakpoint: id, actual_locations: @actualLocations} = res
        breakpoint = new Breakpoint @, @codeDisplay, id, file, line
        @breakpoints[id] = breakpoint
        @codeDisplay.addBreakpoint breakpoint

  changeBreakpoint: (breakpoint) ->
    opts = _.clone breakpoint
    opts.breakpoint = opts.id
    delete opts.id
    @connection.changebreakpoint opts
                    
  clearbreakpoint: (breakpointId) -> 
    @connection.clearbreakpoint breakpointId
    @breakpoints[breakpointId].destroy()
    delete @breakpoints[breakpointId]

  toggleBreakpoint: (editor, line) ->
    file = editor.getPath()
    for id, breakpoint of @breakpoints
      if breakpoint.file is file and
         breakpoint.line is line
        if breakpoint.enabled
          breakpoint.setEnabled no
        else
          @clearbreakpoint breakpoint.id
        return
    @addBreakpoint file, line
    
  getShowExecPosition: (cb) ->
    @connection.getExecPosition 0, (err, res) =>
      @codeDisplay.showCurExecLine res, cb
      
  step: (type) ->
    @connection.step type, =>
      @running = yes
      @ideView.showRunPause @running
      
  run: ->
    @running = yes
    @ideView.showRunPause @running
    @codeDisplay.removeCurExecLine()
    @connection.resume()
    
  setUpConnectionEvents: ->
    @connection.onBreak (body) =>
      @running = no
      {script, sourceLine: line, sourceColumn: column} = body
      file = script.name
      if not fs.existsSync file
        console.log 'node-ide: stepped into file without source:', file
        @codeDisplay.removeCurExecLine()
        @step 'out'
        return
      @codeDisplay.showCurExecLine {file, line, column}
      return
      
  destroy: ->
    for id of @breakpoints then @clearbreakpoint id
    @connection?.destroy()

