###
  lib/breakpoint-mgr.coffee
###

Breakpoint  = require './breakpoint'

module.exports = 
class BreakpointMgr
  
  constructor: (@ideView) ->
    state = @ideView.state
    state.breakpoints ?= {}
    state.active      ?= yes
    state.uncaughtExc ?= yes
    state.caughtExc   ?= no
    {@active, @uncaughtExc, @caughtExc} = state
    
    # console.log 'state in', state
    
    @breakpoints = {}
    for __, breakpoint of state.breakpoints
      breakpoint.active = @active
      newBp = new Breakpoint @, breakpoint
      @breakpoints[newBp.id] = newBp
      console.log 'newBp', breakpoint.line, newBp.line
    state.breakpoints = @breakpoints
    
  setCodeDisplay: (@codeDisplay) ->
  
  setCodeExec: (@codeExec) ->
    if @codeExec
      @codeExec.clearAllBreakpoints()
      fin = 0
      for id, breakpoint of @breakpoints when not breakpoint.destroyed
        @createBreakpoint breakpoint, => 
          if ++fin is @breakpoints.length
            @setActive      @active
            @setUncaughtExc @uncaughtExc
            @setCaughtExc   @caughtExc
        
  createBreakpoint: (breakpoint, cb, file, line, column = 0) -> 
    if (newBreakpoint = file?) 
      for __, bp of @breakpoints when not bp.destroyed
        if file is bp.file and line is bp.line 
          cb? 'duplicate'
          return
      breakpoint = new Breakpoint @, 
                    {file, line, column, active: @ideView.state.active}
    else
      {file, line, column} = breakpoint
      column ?= 0
      
    failure = (msg) =>
      @codeExec?.clearbreakpoint breakpoint
      breakpoint.destroy()
      @ideView.breakpointPanel.update()
      cb? msg
      
    success = =>
      if newBreakpoint then @breakpoints[breakpoint.id] = breakpoint
      @codeDisplay.showBreakpoint breakpoint
      @ideView.breakpointPanel.update()
      cb? null
      
    if @codeExec?.connection
      @codeExec.addBreakpoint breakpoint, (err, {v8Id, line, column, added}) =>
        if err or not added
          failure 'not added'
          return
        breakpoint.updateV8 {v8Id, line, column}
        if newBreakpoint
          for id, bp of @breakpoints when not bp.destroyed
            if file is bp.file and line is bp.line
              failure 'moved to duplicate'
              return
        success()
      return
    success()
  
  changeBreakpoint: (breakpoint) ->
    @codeDisplay.changeBreakpoint breakpoint
    @codeExec?.changeBreakpoint   breakpoint
    @ideView.breakpointPanel.update()
    
  showBreakpoint: (breakpoint) ->
    @codeDisplay.showBreakpoint breakpoint
    
  removeBreakpoint: (breakpoint) ->
    @codeDisplay.removeBreakpoint breakpoint
    @codeExec?.clearbreakpoint    breakpoint
    delete @breakpoints[breakpoint.id]
    breakpoint.destroy()
    @ideView.breakpointPanel.update()
    
  toggleBreakpoint: (file, line) ->
    for id, breakpoint of @breakpoints when not breakpoint.destroyed
      if breakpoint.file is file and
         breakpoint.line is line
        if breakpoint.enabled
          breakpoint.setEnabled no
          @ideView.breakpointPanel.update()
        else
          @removeBreakpoint breakpoint
        return
    if not @active then @setActive yes
    @createBreakpoint null, null, file, line
    
  setActive: (@active) ->
    for id, breakpoint of @breakpoints when not breakpoint.destroyed 
      breakpoint.setActive @active
    @ideView.breakpointPanel.setActive @active
    
  setUncaughtExc: (@uncaughtExc) -> @codeExec?.setUncaughtExc @uncaughtExc
  setCaughtExc  : (@caughtExc)   -> @codeExec?.setCaughtExc   @caughtExc
    
  showAll: (file, line, column) ->
    @codeDisplay.showAll {file, line, column}
    @ideView.breakpointPanel.update()
  
  enableAll:  -> 
    for id, breakpoint of @breakpoints then breakpoint.setEnabled yes
    @ideView.breakpointPanel.update()
  disableAll: -> 
    for id, breakpoint of @breakpoints then breakpoint.setEnabled no
    @ideView.breakpointPanel.update()
  deleteAll:  -> 
    for id, breakpoint of @breakpoints then @removeBreakpoint breakpoint
    @ideView.breakpointPanel.update()
    
  allBreakpointData: ->
    breakpoints = {}
    for id, breakpoint of @breakpoints when not breakpoint.destroyed
      # console.log 'out', breakpoint.toString()
      breakpoints[id] = breakpoint.getData()
    {breakpoints, @active, @uncaughtExc, @caughtExc}
    
  destroy: ->
    @codeDisplay?.destroy()
    