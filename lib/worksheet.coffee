###
  lib/worksheet.coffee
###

pathUtil = require 'path'

module.exports =
class Worksheet
  
  constructor: (@ideView) ->
    {@state, nodeIdeDir} = @ideView
    @worksheetPath = pathUtil.join nodeIdeDir, 'node-ide-worksheet.coffee'
    
  getEditor: ->
    for textEditor in atom.workspace.getTextEditors()
      if textEditor.getPath() is @worksheetPath
        return textEditor
    null
  
  open: ->
    if not @getEditor()
      vpLine = @state.worksheetLine   ? 0
      vpCol  = @state.worksheetColumn ? 0
      atom.workspace.open @worksheetPath, 
        split: 'right', initialLine: vpLine, initialColumn: vpCol
      return yes
    no
        
  saveClose: (chgState = yes) ->
    if chgState then @state.worksheetOpen = no
    if (textEditor = @getEditor())
      point = textEditor.getCursorBufferPosition()
      @state.worksheetLine   = point.row
      @state.worksheetColumn = point.column
      textEditor.saveAs @worksheetPath
      textEditor.destroy()
      return yes
    no
    
          
  destroy: ->
    @saveClose()
