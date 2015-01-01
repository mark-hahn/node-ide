###
  lib/breakpoint.coffee
###

crypto = require 'crypto'

module.exports = 
class Breakpoint
  
  constructor: (@breakpointMgr, args) ->
    {@file, @line, @column, @active, @enabled, @condition, @ignoreCount} = args
    idPlainTxt = @file + '|' + @line + '|' + Date.now()
    @id = crypto.createHash('md5').update(idPlainTxt).digest 'hex'
    if not @ignoreCount?
      @active = @enabled = yes
      @condition = null
      @ignoreCount = 0
      
  changeBreakpoint: -> if not @destroyed then @breakpointMgr.changeBreakpoint @
  
  setActive:      (@active)      -> @changeBreakpoint()
  setEnabled:     (@enabled)     -> @changeBreakpoint()
  setCondition:   (@condition)   -> @changeBreakpoint()
  setIgnoreCount: (@ignoreCount) -> @changeBreakpoint()
      
  getData:  -> {@id, @file, @line, @column, @enabled, @condition, @ignoreCount}
  updateV8: ({@v8Id, @line, @column}) ->
    
  toString: ->
    'bp(' + @file[-9..-1] + ', ' + @line + (if @enabled then ',enbld' else '') + ')'
        
  destroy: ->
    @destroyed = yes
