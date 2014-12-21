###
   lib/code-display.coffee
###

{$}          = require 'atom-space-pen-views'

module.exports =
class CodeDisplay
  
  constructor: (ideVew) ->
    @subs = []
    @breakpointDecorationsById = {}
    @setupEvents()
  
  setCodeExec: (@codeExec) ->

  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
      
  addBreakpoint: (breakpoint) ->
    file = breakpoint.file
    line = breakpoint.line
    editor = @findShowEditor file, line, (editor) ->
      marker = editor.markBufferPosition [line-1, 0]
      decoration = editor.decorateMarker marker, 
                    type: 'gutter', class: 'node-ide-breakpoint-enabled'
      @breakpointDecorationsById[breakpoint.id] = decoration

  showBreakpointEnabled: (breakpointId, enabled) ->
    decoration = @breakpointDecorationsById[breakpointId]
    decoration.setProperties class: 'node-ide-breakpoint' +
                              (if enabled then '-enabled' else '-disabled')
  
  removeBreakpoint: (breakpointId) -> 
      @breakpointDecorationsById[breakpointId].getMarker().destroy()
      delete @breakpointDecorationsById[breakpointId]

  showCurExecLine: (curExecPosition, cb) -> 
    @removeCurExecLine()
    {file, line, column} = curExecPosition
    editor = @findShowEditor file, line, (editor) =>
      @execPosMarker = editor.markBufferPosition [line, 0]
      editor.decorateMarker @execPosMarker, 
                            type: 'line', class: 'node-ide-exec-line'
      cb?()
      
  removeCurExecLine: -> 
    if @execPosMarker
      @execPosMarker.destroy()
      @execPosMarker = null
  
  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $lineNum = $ e.target
      editor = $lineNum.closest('atom-text-editor')[0].getModel()
      line = +$lineNum.attr 'data-buffer-row'
      @codeExec.toggleBreakpoint editor, line
  
  destroy: ->
    @removeCurExecLine()
    for id of @breakpointDecorationsById
        @removeBreakpoint id
    for sub in @subs
      sub.off?()
      sub.dispose?()
