###
  lib/breakpoint-mgr.coffee
###

module.exports = 
class BreakpointMgr
  
  constructor: (@ideView) ->
    {@state, @breakpoints} = @ideView
    
  setCodeDisplay: (@codeDisplay) ->
  
  haveCodeExec: (@codeExec) ->
    fin = 0
    for id, breakpoint of @breakpoints when not breakpoint.destroyed
      @createBreakpoint breakpoint, => 
        if ++fin is @breakpoints.length
          @setActive      @state.active
          @setUncaughtExc @state.uncaughtExc
          @setCaughtExc   @state.caughtExc
        
  createBreakpoint: (breakpoint, cb, file, line, column = 0) -> 
    if (newBreakpoint = file?) 
      for __, bp of @breakpoints when not bp.destroyed
        if file is bp.file and line is bp.line 
          cb? 'duplicate'
          return
      breakpoint = new Breakpoint @, {file, line, column}
    else
      {file, line, column} = breakpoint
      column ?= 0
      
    failure = (msg) =>
      @codeExec?.clearbreakpoint breakpoint
      breakpoint.destroy()
      @ideView.breakpointPanel.update()
      cb? msg
      
    success = =>
      if newBreakpoint 
        @breakpoints[breakpoint.id] = breakpoint
        @state.breakpoints[breakpoint.id] = breakpoint.getData()
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
              failure 'breakpoint location changed to duplicate'
              return
        success()
      return
    success()
  
  changeBreakpoint: (breakpoint) ->
    @codeDisplay.changeBreakpoint breakpoint
    @codeExec?.changeBreakpoint   breakpoint
    
  showBreakpoint: (breakpoint) ->
    @codeDisplay.showBreakpoint breakpoint
    
  removeBreakpoint: (breakpoint) ->
    @codeDisplay.removeBreakpoint breakpoint
    @codeExec?.clearbreakpoint    breakpoint
    delete @breakpoints[breakpoint.id]
    delete @state.breakpoints[breakpoint.id]
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
    if not @state.active then @setActive yes
    @createBreakpoint null, null, file, line
    
  setActive: (active) ->
    @state.active = active
    @codeDisplay?.setActive            active
    @codeExec?.setActive               active
    @ideView.breakpointPanel.setActive active
  
  setUncaughtExc: (uncaughtExc) -> 
    @state.uncaughtExc = uncaughtExc
    @codeExec?.setUncaughtExc @state.uncaughtExc
    
  setCaughtExc  : (caughtExc)   -> 
    @state.caughtExc = caughtExc
    @codeExec?.setCaughtExc   @state.caughtExc
    
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
    
  destroy: ->
    @codeDisplay?.destroy()
    