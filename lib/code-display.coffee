###
   lib/code-display.coffee
###

for provider in atom.views.providers
  if (TextEditor = provider.modelConstructor).name is 'TextEditor'
    break

{$} = require 'atom-space-pen-views'
_   = require 'underscore'

module.exports =
class CodeDisplay
  
  constructor: (@breakpointMgr) ->
    @subs = []
    @setupEvents()
    
    @subs.push atom.workspace.observeActivePaneItem (editor) =>
      if editor instanceof TextEditor 
        @setBreakpointsInEditor editor
    
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
      
  setCursorToLineColDelayed: (editor, line, column) ->
    if editor is atom.workspace.getActivePaneItem()
      setTimeout ->
        editor.setCursorBufferPosition [line, column]
      , 100
  
  showCurExecLine: (curExecPosition, cb) -> 
    @removeCurExecLine()
    {file, line, column} = curExecPosition
    editor = @findShowEditor file, line, (editor) =>
      @execPosMarker = editor.markBufferPosition [line, column]
      editor.decorateMarker @execPosMarker, 
                            type: 'line', class: 'node-ide-exec-line'
      @setCursorToLineColDelayed editor, line, column
      cb?()
      
  removeCurExecLine: -> 
    if @execPosMarker
      @execPosMarker.destroy()
      @execPosMarker = null
  
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
  
  getDecorationData: (breakpoint) ->
    {enabled} = breakpoint type: 'gutter', class: 'node-ide-breakpoint-' +
                            (if breakpoint.enabled then 'enabled' else 'disabled')
    
  setBreakpointsInEditor: (editor) ->
    path = @getPath editor
    editor.nodeIdeDecorations ?= {}
    for id, breakpoint of @breakpointMgr.breakpoints
      if breakpoint.file is path and
         not editor.nodeIdeDecorations[breakpoint.id]
        {line, column} = breakpoint
        marker = editor.markBufferPosition [line, column]
        decoration = editor.decorateMarker marker, @getDecorationData breakpoint
        editor.nodeIdeDecorations[breakpoint.id] = decoration
  
  showBreakpoint: (breakpoint) ->
    file   = breakpoint.file
    line   = breakpoint.line
    column = breakpoint.column
    editor = @findShowEditor file, line, (editor) =>
      @setBreakpointsInEditor editor
      @setCursorToLineColDelayed editor, line, column
      
  changeBreakpoint: (breakpoint) ->
    decorationData = @getDecorationData breakpoint
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeDecorations[breakpoint.id])
        decoration.setProperties decorationData
        @setCursorToLineColDelayed editor, breakpoint.line, breakpoint.column
  
  removeBreakpoint: (breakpoint) -> 
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeDecorations[breakpoint.id])
        marker = decoration.getMarker()
        marker.destroy()
        delete editor.nodeIdeDecorations[breakpoint.id]
        @setCursorToLineColDelayed editor, breakpoint.line, breakpoint.column

  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $tgt = $ e.target
      file = @getPath $tgt.closest('atom-text-editor')[0].getModel()
      line = +$tgt.closest('.line-number').attr 'data-buffer-row'
      @breakpointMgr.toggleBreakpoint file, line
    false
  
  destroy: ->
    @removeCurExecLine()
    for editor in atom.workspace.getTextEditors()
      if editor.nodeIdeDecorations
        for id, decoration of editor.nodeIdeDecorations
          decoration.getMarker().destroy()
        delete editor.nodeIdeDecorations
    for sub in @subs
      sub.off?()
      sub.dispose?()
