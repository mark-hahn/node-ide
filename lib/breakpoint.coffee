###
  lib/breakpoint.coffee
###

module.exports = 
class Breakpoint
  
  constructor: (@ideView, @file, @line, @decoration) ->
    @enabled = yes
    @condition = 'true'
    @ignoreCount = 0
    @conn().setScriptBreakpoint @file, @line, 
            {@enabled, @condition, @ignoreCount}, cb (err, res) ->
      if err
        @destroy()
      else
        {breakpoint: @id, actual_locations: @actualLocations} = res
        @ideView.breakpoints[@id] = @
  
  isReady: -> 
    if not @id or @destroyed or
       not (@conn = @ideView.getCurrentConnection())
      @ideView.showBreakpointError @decoration
      return no
    yes
      
  enable: (@enabled) ->
    if @isReady
      @conn().changebreakpoint \
          {breakpoint: @id, @enabled, @condition, @ignoreCount}
      @ideView.showBreakpointEnabled @decoration, @enabled
    
  destroy: ->
    @destroyed = yes
    @conn()?.clearbreakpoint @id
    @decoration?.getMarker().destroy()
    
        