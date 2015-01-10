###
   lib/code-display.coffee
###

{TextEditor} = require 'atom'
{$} = require 'atom-space-pen-views'
fs  = require 'fs-plus'
_   = require 'underscore'

module.exports =
class CodeDisplay
  
  constructor: (@ideView) ->
    {Disposable, CompositeDisposable} = require 'atom'
    @disposables = new CompositeDisposable
    @subs = []
    
    atom.workspace.observeTextEditors (editor) =>
      file = @getPath editor
      if file is @curExecPosition?.file  then @showCurExecLine()
      else if file is @curFramePosition?.file then @showCurExecLine yes
      @setBreakpointsInEditor editor
      
      shadowRoot  = atom.views.getView(editor).shadowRoot
      $shadowRoot = $ shadowRoot
      lineNumbers = shadowRoot.querySelector '.line-numbers' 
      lineNumberClick = (e) =>
        $tgt = $ e.target
        line = +$tgt.closest('.line-number').attr 'data-buffer-row'
        @ideView.toggleBreakpoint file, line
        false
      lineNumbers.addEventListener 'click', lineNumberClick
      @disposables.add new Disposable ->
        lineNumbers.removeEventListener 'click', lineNumberClick
        
      @subs.push $shadowRoot.find('.gutter .icon-right').on 'click', => @showAll()
      @subs.push $shadowRoot.find('.lines .fold-marker').on 'click', => @showAll()
        
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
  
  findShowEditor: (file, line, column, cb) ->
    if not fs.existsSync file then return
    
    atom.workspace.open file, searchAllPanes: yes, initialLine: line
      .then (editor) -> 
        if editor is atom.workspace.getActivePaneItem() then setTimeout ->
          editor.setCursorBufferPosition [line, column]
        , 50
        cb? editor
  
  showCurExecLine: (execPosition, isFrame) ->
    if execPosition
      if isFrame then  @curFramePosition = execPosition
      else @curExecPosition = execPosition
    if @curExecPosition?.file is @curFramePosition?.file and
       @curExecPosition?.line is @curFramePosition?.line
      isFrame = no
    @removeCurExecLine isFrame, yes
    position = (if isFrame then  @curFramePosition else @curExecPosition)
    if position
      {file, line, column} = position
      @findShowEditor file, line, column, =>
        for editor in atom.workspace.getTextEditors() 
          if @getPath(editor) is file
            if isFrame
              editor.nodeIdeFrameMarker = editor.markBufferPosition [line, column]
              editor.decorateMarker editor.nodeIdeFrameMarker, 
                                      type: 'gutter', class: 'node-ide-frame-line'
            else
              editor.nodeIdeExecMarker = editor.markBufferPosition [line, column]
              editor.decorateMarker editor.nodeIdeExecMarker, 
                                      type: 'gutter', class: 'node-ide-exec-line'
        null
  
  removeCurExecLine: (isFrame = no, temp = no) ->
    if not temp
      if isFrame then delete @curFramePosition
      else delete @curExecPosition
    for editor in atom.workspace.getTextEditors()
      if isFrame
        editor.nodeIdeFrameMarker?.destroy()
        delete editor.nodeIdeFrameMarker
      else        
        editor.nodeIdeExecMarker?.destroy()
        delete editor.nodeIdeExecMarker
    null

  getDecorationData: (breakpoint) ->
    enbldActive = breakpoint.enabled and breakpoint.active
    type: 'gutter', class: 'node-ide-breakpoint-' +
      (if enbldActive then 'enabled' else 'disabled')
      
  removeBreakpointsFromEditor: (editor) ->
    if editor.nodeIdeBreakpoints
      for id, decoration of editor.nodeIdeBreakpoints
        decoration.getMarker()?.destroy()
      delete editor.nodeIdeBreakpoints
  
  setBreakpointsInEditor: (editor) ->
    path = @getPath editor
    @removeBreakpointsFromEditor editor
    editor.nodeIdeBreakpoints = {}
    for id, breakpoint of @ideView.breakpointMgr.breakpoints
      if breakpoint.file is path and not editor.nodeIdeBreakpoints[id]
        {line, column} = breakpoint
        marker = editor.markBufferPosition [line, column]
        decoration = editor.decorateMarker marker, @getDecorationData breakpoint
        editor.nodeIdeBreakpoints[id] = decoration
    null
    
  setAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      @setBreakpointsInEditor editor
    null
  
  showBreakpoint: (breakpoint) ->
    {file, line, column} = breakpoint
    @findShowEditor file, line, column, (editor) =>
      editor.unfoldBufferRow line
      @setAllBreakpoints()
      null
      
  changeBreakpoint: (breakpoint) ->
    decorationData = @getDecorationData breakpoint
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeBreakpoints?[breakpoint.id])
        decoration.setProperties decorationData
    null
    
  removeBreakpoint: (breakpoint) -> 
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeBreakpoints?[breakpoint.id])
        decoration.getMarker()?.destroy()
    null    
    
  removeAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      @removeBreakpointsFromEditor editor
    null
    
  showAll: (execPosition) ->
    setTimeout =>
      @setAllBreakpoints()
      @showCurExecLine execPosition
    , 50
    
  destroy: ->
    @removeCurExecLine()
    @removeCurExecLine yes
    @removeAllBreakpoints()
    @disposables.dispose()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    null
    