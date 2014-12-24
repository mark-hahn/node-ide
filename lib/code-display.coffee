###
   lib/code-display.coffee
###

{TextEditor} = require 'atom'
{$} = require 'atom-space-pen-views'
_   = require 'underscore'

module.exports =
class CodeDisplay
  
  constructor: (@breakpointMgr) ->
    @subs = []
    @setupEvents()
    
    @subs.push atom.workspace.observeActivePaneItem (editor) =>
      if editor instanceof TextEditor 
        if @curExecPosition and not editor.nodeIdeExecMarker and
           @getPath(editor) is @curExecPosition?.file
          @showCurExecLine @curExecPosition
        @setBreakpointsInEditor editor
    
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
  
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
      
  positionVisible: (file, line, column) ->
    visible = (editor = atom.workspace.getActivePaneItem()) and
               editor instanceof TextEditor and
               @getPath(editor) is file
    if visible then @setCursorToLineColDelayed editor, line, column
    visible
      
  showCurExecLine: (@curExecPosition) ->
    @removeCurExecLine yes
    if @curExecPosition
      {file, line, column} = @curExecPosition
      showing = @positionVisible file, line, column
      for editor in atom.workspace.getTextEditors()
        if @getPath(editor) is file
          if not showing
            showing = yes
            @findShowEditor file, line, (editor) =>
              @setCursorToLineColDelayed editor, line, column
          editor.nodeIdeExecMarker = editor.markBufferPosition [line, column]
          editor.decorateMarker editor.nodeIdeExecMarker, 
                                type: 'line', class: 'node-ide-exec-line'
      if not showing
        @findShowEditor file, line, (editor) =>
          @setCursorToLineColDelayed editor, line, column 
      
  removeCurExecLine: (temp = no) ->
    if not temp then delete @curExecPosition
    for editor in atom.workspace.getTextEditors()
      editor.nodeIdeExecMarker?.destroy()
      delete editor.nodeIdeExecMarker
  
  getDecorationData: (breakpoint) ->
    {enabled} = breakpoint 
    type: 'gutter', class: 'node-ide-breakpoint-' +
      (if breakpoint.enabled then 'enabled' else 'disabled')
    
  setCursorToLineColDelayed: (editor, line, column) ->
    if editor is atom.workspace.getActivePaneItem()
      setTimeout ->
        editor.setCursorBufferPosition [line, column]
      , 100
  
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
    {file, line, column} = breakpoint
    showing = @positionVisible file, line, column    
    for editor in atom.workspace.getTextEditors()
      if @getPath(editor) is file
        if not showing
          showing = yes
          @findShowEditor file, line, (editor) =>
            @setCursorToLineColDelayed editor, line, column
      @setBreakpointsInEditor editor
    if not showing
      @findShowEditor file, line, (editor) =>
        @setCursorToLineColDelayed editor, line, column 
      
  changeBreakpoint: (breakpoint) ->
    decorationData = @getDecorationData breakpoint
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeDecorations?[breakpoint.id])
        decoration.setProperties decorationData
  
  removeBreakpoint: (breakpoint) -> 
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeDecorations?[breakpoint.id])
        decoration.getMarker().destroy()
        delete editor.nodeIdeDecorations[breakpoint.id]
        
  removeAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      if editor.nodeIdeDecorations
        for id, decoration of editor.nodeIdeDecorations
          decoration.getMarker().destroy()
        delete editor.nodeIdeDecorations

  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $tgt = $ e.target
      file = @getPath $tgt.closest('atom-text-editor')[0].getModel()
      line = +$tgt.closest('.line-number').attr 'data-buffer-row'
      @breakpointMgr.toggleBreakpoint file, line
    false
  
  destroy: ->
    @removeCurExecLine()
    @removeAllBreakpoints()
    for sub in @subs
      sub.off?()
      sub.dispose?()
