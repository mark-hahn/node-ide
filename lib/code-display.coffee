###
   lib/code-display.coffee
###

{$} = require 'atom-space-pen-views'

module.exports =
class CodeDisplay
  
  constructor: (ideVew) ->
    @subs = []
    @breakpointDecorationsById = {}
    @setupEvents()
  
  setCodeExec: (@codeExec) ->

  setCursorToLineColDelayed: (line, column) ->
    setTimeout -> 
      atom.workspace.getActiveTextEditor()
          .setCursorBufferPosition [line, column]
    , 100
    
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
      
  showCurExecLine: (curExecPosition, cb) -> 
    @removeCurExecLine()
    {file, line, column} = curExecPosition
    editor = @findShowEditor file, line, (editor) =>
      @execPosMarker = editor.markBufferPosition [line, column]
      editor.decorateMarker @execPosMarker, 
                            type: 'line', class: 'node-ide-exec-line'
      @setCursorToLineColDelayed line, column
      cb?()
      
  removeCurExecLine: -> 
    if @execPosMarker
      @execPosMarker.destroy()
      @execPosMarker = null
  
  addBreakpoint: (breakpoint) ->
    file   = breakpoint.file
    line   = breakpoint.line
    column = breakpoint.column
    editor = @findShowEditor file, line, (editor) =>
      marker = editor.markBufferPosition [line, column]
      decoration = editor.decorateMarker marker, 
                    type: 'gutter', class: 'node-ide-breakpoint-enabled'
      @breakpointDecorationsById[breakpoint.id] = decoration
      @setCursorToLineColDelayed line, column

  showBreakpointEnabled: (breakpoint, enabled) ->
    decoration = @breakpointDecorationsById[breakpoint.id]
    decoration.setProperties 
      type:  'gutter'
      class: 'node-ide-breakpoint' +
              (if enabled then '-enabled' else '-disabled')
      @setCursorToLineColDelayed breakpoint.line, breakpoint.column
      
  removeBreakpoint: (breakpointId) -> 
    if (decoration = @breakpointDecorationsById[breakpointId])
      marker = decoration.getMarker()
      pos = marker.getBufferRange().start
      @setCursorToLineColDelayed pos.row, pos.column
      marker.destroy()
      delete @breakpointDecorationsById[breakpointId]

  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $tgt = $ e.target
      editor = $tgt.closest('atom-text-editor')[0].getModel()
      line   = $tgt.closest('.line-number').attr 'data-buffer-row'
      @codeExec.toggleBreakpoint editor, +line
    false
  
  destroy: ->
    @removeCurExecLine()
    for id of @breakpointDecorationsById
        @removeBreakpoint id
    for sub in @subs
      sub.off?()
      sub.dispose?()
