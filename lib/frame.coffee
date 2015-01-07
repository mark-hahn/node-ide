###
  lib/frame.coffee
###

crypto = require 'crypto'

module.exports = 
class Frame
  
  constructor: (@stackPanel, args) ->
    {@file, @line, @column, @active, @enabled, @condition, @ignoreCount} = args
    idPlainTxt = @file + '|' + @line + '|' + Date.now()
    @id = crypto.createHash('md5').update(idPlainTxt).digest 'hex'
    if not @ignoreCount?
      @active = @enabled = yes
      @condition = null
      @ignoreCount = 0
      
  changeFrame: -> if not @destroyed then @frameMgr.changeFrame @
  
  setActive:      (@active)      -> @changeFrame()
  setEnabled:     (@enabled)     -> @changeFrame()
  setCondition:   (@condition)   -> @changeFrame()
  setIgnoreCount: (@ignoreCount) -> @changeFrame()
      
  getData:  -> {@id, @file, @line, @column, @enabled, @condition, @ignoreCount}
  updateV8: ({@v8Id, @line, @column}) ->
    
  toString: ->
    'bp(' + @file[-9..-1] + ', ' + @line + (if @enabled then ',enbld' else '') + ')'
        
  destroy: ->
    @destroyed = yes
