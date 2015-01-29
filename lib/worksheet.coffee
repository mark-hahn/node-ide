###
  lib/worksheet.coffee
###

pathUtil  = require 'path'
ExprValue = require './expr-value'

module.exports =
class Worksheet
  
  constructor: (@ideView) ->
    {@state, nodeIdeDir} = @ideView
    @worksheetPath = pathUtil.join nodeIdeDir, 'node-ide-worksheet.coffee'
    @exprValues = []
    @chkOpen()
    
  setAllExprValues: ->
    @destroyAllExprValues()
    for row in [0...@editor.getLineCount()]
      if ExprValue.hasArrow @editor, row
        @exprValues.push new ExprValue @, row
    
  destroyAllExprValues: ->
    for exprValue in @exprValues then exprValue.destroy()
    @exprValues = []
    
  updateAllRows: ->
    exprValuesByRow = {}
    for exprValue in @exprValues
      exprValuesByRow[exprValue.getRow()] = exprValue
    for row in [0...@editor.getLineCount()]
      if (exprValue = exprValuesByRow[row])
        exprValue.update()
      else if ExprValue.hasArrow @editor, row
        @exprValues.push new ExprValue @, row
    
  watchEditor: ->
    self = @  #  fat arrow doesn't work -- bug in coffeescript?  
    @editorSub ?= @editor.onDidChange ->
      if not self.changingBuffer and not changeTimeout
        if changeTimeout then clearTimeout changeTimeout
        changeTimeout = setTimeout ->
          self.updateAllRows()
        , 600
  
  unwatchEditor: ->
    @editorSub?.dispose()
    @editorSub = null
    
  getEditor: ->
    for textEditor in atom.workspace.getTextEditors()
      if textEditor.getPath() is @worksheetPath
        return (@editor = textEditor)
    (@editor = null)
    
  chkOpen: -> 
    if @getEditor() 
      @watchEditor() 
      @updateAllRows()
    else 
      @unwatchEditor()
    @editor?

  open: ->
    if not @chkOpen()
      opts = 
        split: 'right'
        initialLine:   @state.worksheetLine   ? 0
        initialColumn: @state.worksheetColumn ? 0
      atom.workspace.open(@worksheetPath, opts).then => @chkOpen()
      return

  saveClose: (chgState = yes) ->
    if chgState then @state.worksheetOpen = no
    @destroyAllExprValues()
    if @getEditor()
      point = @editor.getCursorBufferPosition()
      @state.worksheetLine   = point.row
      @state.worksheetColumn = point.column
      @editor.saveAs @worksheetPath
      @unwatchEditor()
      @editor.destroy()
      @editor = null
      return yes
    no

  evalExpression: (expr, cb) -> @ideView.evalExpression expr, cb
          
  destroy: ->
    @saveClose()
