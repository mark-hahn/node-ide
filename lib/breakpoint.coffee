###
  lib/breakpoint.coffee
###

module.exports = 
class Breakpoint
  
  constructor: (@codeExec, @codeDisplay, @id, @file, @line) ->
    @enabled = yes
    @condition = 'true'
    @ignoreCount = 0
  
  isReady: -> not @destroyed and @codeExec.isConnected()
  
  setEnabled: (@enabled) -> 
    if @isReady 
      @codeExec.changeBreakpoint @
      @codeDisplay.showBreakpointEnabled @id, @enabled
  
  setCondition:   (@condition)   ->
    if @isReady then @codeExec.changeBreakpoint @
    
  setIgnoreCount: (@ignoreCount) ->
    if @isReady then @codeExec.changeBreakpoint @
      
  destroy: ->
    @destroyed = yes
    @codeDisplay.removeBreakpoint @id
    