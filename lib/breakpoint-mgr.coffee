###
  lib/breakpoint-mgr.coffee
###

Breakpoint  = require './breakpoint'
CodeDisplay = require './code-display'

module.exports = 
class BreakpointMgr
  
  constructor: (@ideView) ->
    state = @ideView.state
    state.breakpoints ?= {}
    state.active      ?= yes
    state.uncaughtExc ?= yes
    state.caughtExc   ?= no
    {@active, @uncaughtExc, @caughtExc} = state
    
    @breakpoints = {}
    for id, breakpoint of state.breakpoints
      @breakpoints[id] = new Breakpoint @, breakpoint
    state.breakpoints = @breakpoints
    
    @codeDisplay = new CodeDisplay @
  
  setCodeExec: (@codeExec) ->
    if @codeExec
      @codeExec.clearAllBreakpoints()
      fin = 0
      for id, breakpoint of @breakpoints
        @createBreakpoint breakpoint, => 
          if ++fin is @breakpoints.length
            @setActive      @active
            @setUncaughtExc @uncaughtExc
            @setCaughtExc   @caughtExc
        
  createBreakpoint: (breakpoint, cb, file, line, column = 0) -> 
    if (newBreakpoint = file?) 
      for id, bp of @breakpoints
        if file is bp.file and line is bp.line then return
      breakpoint = new Breakpoint @, {file, line, column}
    else
      {file, line, column} = breakpoint
      column ?= 0
      
    failure = =>
      @codeExec.clearbreakpoint breakpoint
      breakpoint.destroy()
      cb? 'failed'
      
    success = =>
      if newBreakpoint then @breakpoints[breakpoint.id] = breakpoint
      @codeDisplay.showBreakpoint breakpoint
      cb? null
      
    if @codeExec
      @codeExec.addBreakpoint breakpoint, (err, {v8Id, line, column, added}) =>
        if err or not added
          failure()
          return
        breakpoint.updateV8 {v8Id, line, column}
        if newBreakpoint
          for id, bp of @breakpoints
            if file is bp.file and line is bp.line
              failure()
              return
        success()
      return
    success()
    
  changeBreakpoint: (breakpoint) ->
    @codeDisplay.changeBreakpoint breakpoint
    @codeExec?.changeBreakpoint   breakpoint
    
  removeBreakpoint: (breakpoint) ->
    @codeDisplay.removeBreakpoint breakpoint
    @codeExec?.clearbreakpoint    breakpoint
    delete @breakpoints[breakpoint.id]
    breakpoint.destroy()
    
  toggleBreakpoint: (file, line) ->
    for id, breakpoint of @breakpoints
      if breakpoint.file is file and
         breakpoint.line is line
        if breakpoint.enabled
          breakpoint.setEnabled no
        else
          @removeBreakpoint breakpoint
        return
    @createBreakpoint null, null, file, line
    
  setActive: (@active) ->
    for id, breakpoint of @breakpoints 
      breakpoint.setActive @active
  setUncaughtExc: (@uncaughtExc) -> @codeExec?.setUncaughtExc @uncaughtExc
  setCaughtExc  : (@caughtExc)   -> @codeExec?.setCaughtExc   @caughtExc
    
  enableAll:  -> for id, breakpoint of @breakpoints then breakpoint.setEnabled yes
  disableAll: -> for id, breakpoint of @breakpoints then breakpoint.setEnabled no
  deleteAll:  -> for id, breakpoint of @breakpoints then @removeBreakpoint breakpoint
    
  allBreakpointData: ->
    breakpoints = {}
    for id, breakpoint of @breakpoints
      breakpoints[id] = breakpoint.getData()
    {breakpoints, @active, @uncaughtExc, @caughtExc}
    
  destroy: ->
    @codeDisplay?.destroy()
    