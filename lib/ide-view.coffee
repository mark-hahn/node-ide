
{$, View}    = require 'atom-space-pen-views'

Breakpoint   = require './breakpoint'
V8connection = require './v8-connection'

dbgHost = '127.0.0.1'
dbgPort = 5858

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
      @parent().addClass('ide-tool-panel').show()
      @setupEvents()
      
      @connection = new V8connection @
      @connection.connect dbgHost, dbgPort, (err) =>
        if err 
          @connection = null
          return
        @setUpConnectionEvents()
        
        @connection.version (err, res) =>
          {V8Version, @running} = res
          console.log 'node-ide: connected to V8 version:', {V8Version, @running}
          @showRunPause()
          if not @running
            @showRunPause()
            @getShowExecPosition()
            return
            
          @connection.suspend => 
            @running = no
            @showRunPause()
            @getShowExecPosition()
              
  getElement: -> @
  getCurrentConnection: -> @connection
  
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
      
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
    
  showCurExecLine: (cb) -> 
    @hideCurExecLine()
    {file, line, column} = @curExecPosition 
    editor = @findShowEditor file, line, (editor) =>
      @execMarker = editor.markBufferPosition [line, 0]
      editor.decorateMarker @execMarker, 
                            type: 'line', class: 'node-ide-exec-line'
      cb?()
      
  hideCurExecLine: -> 
    if @execMarker
      @execMarker.destroy()
      @execMarker = null
  
  getShowExecPosition: (cb) ->
    @connection.getExecPosition 0, (err, res) =>
      @curExecPosition = res
      @showCurExecLine cb
      
  showRunPause: ->
    if @running
      @idePause.css display: 'inline-block'
      @idePlay.hide()
    else
      @idePlay.css display: 'inline-block'
      @idePause.hide()      
  
  run: ->
    @running = yes
    @showRunPause()
    
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
      
    @subs.push @on 'click', '.ide-step-over', (e) =>
      @connection.step 'next', =>
        @running = yes
        @showRunPause()
      
  setUpConnectionEvents: ->
    @connection.onBreak (body) =>
      @running = no
      {script, sourceLine: line, sourceColumn: column} = body
      file = script.name
      if process.platform is 'win32' then file = file.toLowerCase()
      for dir in atom.project.getDirectories()
        path = dir.path
        if process.platform is 'win32' then path = path.toLowerCase()
        if file.indexOf(path) is 0
          @curExecPosition = {file, line, column}
          @showCurExecLine()
          return
      console.log 'node-ide: stepped into file outside of project:', file
      @hideCurExecLine()
      @connection.resume => @running = yes
      
  serialize: ->

  destroy: ->
    for id, breakpoint of @breakpoints then breakpoint.destroy()
    @execMarker?.destroy()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    @connection?.destroy()
    @remove()

