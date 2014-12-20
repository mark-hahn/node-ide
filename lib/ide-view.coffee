
{$, View}    = require 'atom-space-pen-views'

Breakpoint   = require './breakpoint'
V8connection = require './v8-connection'

dbgHost = '127.0.0.1'
dbgPort = '5858'

module.exports =
class IdeView extends View
  @content: ->
    @div class: 'node-ide', =>
      @div class: 'logo', "Node-IDE"
      @div outlet:'idePause', class:'new-btn ide-pause'
      @div outlet:'idePlay',  class:'new-btn ide-play'
      @div outlet:'ideOver',  class:'new-btn ide-step-over'
      @div outlet:'ideIn',    class:'new-btn ide-step-in'
      @div outlet:'ideOut',   class:'new-btn ide-step-out'

  initialize: (nodeIDE) ->
    @subs = []
    @breakpoints = {}
    @running = yes
    process.nextTick =>
      @parent().addClass 'ide-tool-panel'
      @setupEvents()
      
      @connection = new V8connection @
      @connection.connect dbgHost, dbgPort, (err) ->
        if err 
          atom.confirm 
            message: 'node-ide: unable to connect to target\n'
            detailedMessage: "host: #{dbgHost}, port: #{dbgPort}"
          @connection = null
          return
        @setUpConnectionEvents()
  
  getElement: -> @
  getCurrentConnection: -> @connection
  
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .next (editor) -> cb editor
      
  showBreakpointEnabled: (decoration, enabled) ->
    decoration.setProperties class: 'node-ide-breakpoint' +
                              (if enabled then '-enabled' else '-disabled')
      
  showBreakpointError: (decoration) ->
    decoration.setProperties class: 'node-ide-breakpoint-error'
      
  addBreakpoint: (file, line) ->
    editor = @findShowEditor file, line, (editor) ->
      marker = editor.markBufferPosition [line-1, 0]
      decoration = editor.decorateMarker marker, 
                    type: 'gutter', class: 'node-ide-breakpoint-enabled'
      new Breakpoint @, file, line, decoration

  toggleBreakpoint: (line) ->
    toggleBreakpoint row
    
    editor = atom.workspace.getActiveTextEditor()
    
  showCurExecLine: -> 
    @hideCurExecLine()
    {file, line, column} = @curExecPosition 
    editor = @findShowEditor file, line, (editor) ->
      @execMarker = editor.markBufferRange [[line-1, 0], [line, 0]]
      editor.decorateMarker @execMarker, 
                            type: 'line', class: 'node-ide-exec-line'
      
  hideCurExecLine: -> 
    if @execMarker
      @execMarker.destroy()
      @execMarker = null
  
  run: ->
    @idePause.css display: 'inline-block'
    @idePlay.hide()
    @hideCurExecLine()
    @curExecPosition = null
    @connection.resume()
    @running = yes
    
  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $lineNum = $ e.target
      editor = $lineNum.closest('atom-text-editor')[0].getModel()
      row = +$lineNum.attr('data-buffer-row') + 1
      @toggleBreakpoint row
      
  setUpConnectionEvents: ->
    @connection.onBreak (body) =>
      {script: file, sourceLine: line, sourceColumn: column} = body
      @curExecPosition = {file, line, column}
      console.log 'break:', @curExecPosition
      @showCurExecLine()
      @idePlay.css display: 'inline-block'
      @idePause.hide()
      @running = no
      
  serialize: ->

  destroy: ->
    for id, breakpoint of @breakpoints then breakpoint.destroy()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    @connection?.destroy()
    @remove()

