###
  lib/breakpoint.coffee
###

module.exports = 
class Breakpoint
  
  constructor: (@codeExec, @codeDisplay, @id, @file, @line, @column) ->
    @enabled = yes
    @condition = 'true'
    @ignoreCount = 0
  
  isReady: -> not @destroyed and @codeExec.isConnected()
  
  setEnabled: (@enabled) -> 
    if @isReady 
      @codeExec.changeBreakpoint @
      @codeDisplay.showBreakpointEnabled @, @enabled
  
  setCondition:   (@condition)   ->
    if @isReady then @codeExec.changeBreakpoint @
    
  setIgnoreCount: (@ignoreCount) ->
    if @isReady then @codeExec.changeBreakpoint @
      
  destroy: ->
    @destroyed = yes
    @codeDisplay.removeBreakpoint @id
    