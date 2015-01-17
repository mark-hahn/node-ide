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
    @subs   = []
    @frames = []
    
    atom.workspace.observeTextEditors (editor) =>
      file = @getPath editor
      @setFramesInEditor      editor
      @setBreakpointsInEditor editor
      
      $shadowRoot = $ atom.views.getView(editor).shadowRoot
      $lineNumbers = $shadowRoot.children().find '.line-numbers' 
      @subs.push $lineNumbers.click (e) =>
        $tgt = $ e.target
        line = +$tgt.closest('.line-number').attr 'data-buffer-row'
        @ideView.toggleBreakpoint file, line
        false
        
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
  
  findShowEditor: (file, line, column, cb) ->
    if not fs.existsSync file then return
    atom.workspace.open file, searchAllPanes: yes, initialLine: line
      .then (editor) -> 
        setTimeout (-> editor.setCursorBufferPosition [line, column]), 50
        cb? editor

  setStack: (@frames, @refs) ->
  
  removeFramesFromEditor: (editor) ->
    if editor.nodeIdeFrames
      for decoration in editor.nodeIdeFrames
        decoration.getMarker()?.destroy()
      delete editor.nodeIdeFrames
  
  setFramesInEditor: (editor) ->
    path = @getPath editor
    @removeFramesFromEditor editor
    editor.nodeIdeFrames = []
    for frame, idx in @frames 
      if frame.file is path
        {line, column} = frame
        marker = editor.markBufferPosition [line, column]
        decoration = editor.decorateMarker marker, 
            type: 'line-number'
            class: (if idx is 0 then 'node-ide-exec-line' else 'node-ide-frame-line')
        editor.nodeIdeFrames.push decoration
    null
    
  setAllFrames: ->
    for editor in atom.workspace.getTextEditors()
      @setFramesInEditor editor
    null
  
  showFrame: (frame) ->
    {file, line, column} = frame
    @findShowEditor file, line, column, (editor) =>
      editor.unfoldBufferRow line
      # @setFramesInEditor editor
      null
      
  clearFrames: ->
    for editor in atom.workspace.getTextEditors()
      @removeFramesFromEditor editor
    @frames = []
      
  getDecorationData: (breakpoint) ->
    enbldActive = breakpoint.enabled and @active
    type: 'line-number', class: 'node-ide-breakpoint-' +
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
    
  setActive: (@active) -> 
    @setAllBreakpoints()
    
  showAll: ->
    setTimeout => 
      @setAllFrames()
      @setAllBreakpoints()
    , 50

  destroy: ->
    @clearFrames()
    @removeAllBreakpoints()
    @disposables.dispose()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    null
    