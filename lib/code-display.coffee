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
    
    # @subs.push atom.workspace.observeActivePaneItem (editor) =>
    #   if editor instanceof TextEditor 
    #     if @curExecPosition and @getPath(editor) is @curExecPosition?.file
    #        @showCurExecLine @curExecPosition, editor
    #     @setBreakpointsInEditor editor
    
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
  
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
  
  setCursorToLineColDelayed: (editor, line, column) ->
    if editor is atom.workspace.getActivePaneItem()
      setTimeout ->
        editor.setCursorBufferPosition [line, column]
      , 50
  
  addCurExecPosDiv: (editor, line, column) ->
    editor.unfoldBufferRow line
    $editor = $ atom.views.getView editor
    $execLineNumber = $editor.find '.line-number-' + line
    if not ($execIcon = $execLineNumber.find '.ide-exec-pos').length
      $execLineNumber.append \
        '<div class="ide-exec-pos">&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;</div>'
      
  showCurExecLine: (@curExecPosition) ->
    @removeCurExecLine yes
    if @curExecPosition
      {file, line, column} = @curExecPosition
      @findShowEditor file, line, (editor) =>
        @addCurExecPosDiv editor, line, column
        @setCursorToLineColDelayed editor, line, column
        for editor in atom.workspace.getTextEditors() 
          if @getPath(editor) is file
            @addCurExecPosDiv editor, line, column
        null
      
  removeCurExecLine: (temp = no) ->
    $('.workspace .editor .gutter').find('.ide-exec-pos').remove()
    if not temp then delete @curExecPosition
  
  setBreakpointsInEditor: (editor) ->
    path = @getPath editor
    editor.nodeIdeBreakpoints ?= {}
    for id, breakpoint of @breakpointMgr.breakpoints
      if breakpoint.file is path
        if not ($bp = editor.nodeIdeBreakpoints[id])
          {line, column} = breakpoint
          $bp = $ '<div class="ide-breakpoint"></div>'
          $editor = $ atom.views.getView editor
          $execLineNumber = $editor.find '.line-number-' + line
          $execLineNumber.append $bp
          editor.nodeIdeBreakpoints[id] = $bp
        if breakpoint.enabled then $bp.addClass 'enabled'
        else $bp.removeClass 'enabled'
    null
    
  showBreakpoint: (breakpoint) ->
    {file, line, column} = breakpoint
    @findShowEditor file, line, (editor) =>
      editor.unfoldBufferRow line
      @setBreakpointsInEditor editor
      @setCursorToLineColDelayed editor, line, column
      for editor in atom.workspace.getTextEditors()
        if @getPath(editor) is file
          @setBreakpointsInEditor editor
      null
      
  changeBreakpoint: (breakpoint) ->
    for editor in atom.workspace.getTextEditors()
      if ($bp = editor.nodeIdeBreakpoints[breakpoint.id])
        if breakpoint.enabled then $bp.addClass 'enabled'
        else $bp.removeClass 'enabled'
    null
    
  removeBreakpoint: (breakpoint) -> 
    id = breakpoint.id
    for editor in atom.workspace.getTextEditors()
      if ($bp = editor.nodeIdeBreakpoints[id])
        $bp.remove()
        delete editor.nodeIdeBreakpoints[id]
    null    
    
  removeAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      if editor.nodeIdeBreakpoints
        for id, $bp of editor.nodeIdeBreakpoints
          $bp.remove()
          delete editor.nodeIdeBreakpoints[id]
    null

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
    null
    