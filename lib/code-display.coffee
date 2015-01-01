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
    
    atom.workspace.observeTextEditors (editor) =>
      if @curExecPosition and @getPath(editor) is @curExecPosition?.file
         @showCurExecLine @curExecPosition
      @setBreakpointsInEditor editor
      
    @setupEvents()
  
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
      
  showCurExecLine: (execPosition) ->
    if execPosition then @curExecPosition = execPosition
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
    $editor = $ atom.views.getView editor
    $editor.find('.ide-breakpoint').remove()
    for id, breakpoint of @breakpointMgr.breakpoints
      if breakpoint.file is path
        {line, column} = breakpoint
        if not (($line = $editor.find('.line-number[data-buffer-row="' + 
                                      line + '"]')).length and
                ($bp = $line.find('.ide-breakpoint')).length)
          $bp = $ '<div class="ide-breakpoint"></div>'
          if $line.length then $line.append $bp
        if breakpoint.enabled and breakpoint.active
             $bp.addClass    'enabled'
        else $bp.removeClass 'enabled'
    null

  setAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      @setBreakpointsInEditor editor
    
  showBreakpoint: (breakpoint) ->
    {file, line, column} = breakpoint
    @findShowEditor file, line, (editor) =>
      editor.unfoldBufferRow line
      @setAllBreakpoints()
      @setCursorToLineColDelayed editor, line, column
      null
      
  changeBreakpoint: (breakpoint) ->
    for editor in atom.workspace.getTextEditors()
      $editor = $ atom.views.getView editor
      $editor.find('.ide-breakpoint').each (i, ele) =>
        $bp = $ ele
        if +$bp.closest('.line-number').attr('data-buffer-row') is
           breakpoint.line
          if breakpoint.enabled and breakpoint.active
               $bp.addClass    'enabled'
          else $bp.removeClass 'enabled'
    null
    
  removeBreakpoint: (breakpoint) -> 
    for editor in atom.workspace.getTextEditors()
      $editor = $ atom.views.getView editor
      $editor.find('.ide-breakpoint').each (i, ele) =>
        $bp = $ ele
        if +$bp.closest('.line-number').attr('data-buffer-row') is
           breakpoint.line
          $bp.remove()
    null    

  removeAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      $editor = $ atom.views.getView editor
      $editor.find('.ide-breakpoint').remove()
    null
    
  showAll: (execPosition, fromEditor) ->
    if not fromEditor
      setTimeout =>
        @setAllBreakpoints()
        @showCurExecLine execPosition
      , 50

  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $tgt = $ e.target
      file = @getPath $tgt.closest('atom-text-editor')[0].getModel()
      line = +$tgt.closest('.line-number').attr 'data-buffer-row'
      @breakpointMgr.toggleBreakpoint file, line
    false
    
    @subs.push $('.workspace .gutter .icon-right').on 'click', => @showAll()
    @subs.push $('.workspace .lines .fold-marker').on 'click', => @showAll()
  
  destroy: ->
    @removeCurExecLine()
    @removeAllBreakpoints()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    null
    