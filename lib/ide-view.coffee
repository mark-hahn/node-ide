
{$,View} = require 'atom-space-pen-views'
{TextEditor} = require 'atom'
util = require 'util'

Dock            = require './dock'
BreakpointMgr   = require './breakpoint-mgr'
CodeDisplay     = require './code-display'
CodeExec        = require './code-exec'
BreakpointPanel = require './breakpoint-panel'
StackPanel      = require './stack-panel'

module.exports =
class IdeView extends View
  
  @content: ->
    @div class: 'node-ide', =>
      @div class: 'logo', "Node-IDE"
      @div outlet:'ideConn',  class:'new-btn octicon ide-conn'
      
      @div outlet: 'execButtons', class: 'exec-buttons', =>
        @div outlet:'idePause', class:'new-btn octicon ide-pause'
        @div outlet:'ideRun',   class:'new-btn octicon ide-run'
        @div outlet:'ideOver',  class:'new-btn octicon ide-step-over'
        @div outlet:'ideIn',    class:'new-btn octicon ide-step-in'
        @div outlet:'ideOut',   class:'new-btn octicon ide-step-out'
      @div class:'btn-separator'
      @div class: 'inspector-buttons', =>
        @div outlet:'stopSign', class:'new-btn octicon ide-bp-btn ide-stop'
        @div class:'new-btn octicon ide-stack-btn ide-stack'
        @div class:'new-btn octicon ide-var-page-btn ide-eye'

  initialize: (@nodeIde) ->
    {@state, @internalFileDir, @varPagePath, @breakpoints} = @nodeIde
    
    # console.log 'IdeView initialize', util.inspect @state, depth: null
    
    @subs = []
    process.nextTick =>
      @setupEvents()
      @breakpointMgr   = new BreakpointMgr   @
      @codeDisplay     = new CodeDisplay     @
      @dock            = new Dock            @
      @breakpointPanel = new BreakpointPanel @
      @stackPanel      = new StackPanel      @
      
      @showConnected no
      @toggleConnection()
      
      @breakpointMgr.setCodeDisplay   @codeDisplay
      @breakpointPanel.setUncaughtExc @state.uncaughtExc
      @breakpointPanel.setCaughtExc   @state.caughtExc
      
      if @state.breakpointPanelDocked then @dock.add @breakpointPanel
      if @state.stackPanelDocked      then @dock.add @stackPanel
      if @state.varPageOpen           then @openVarPage()
      
  getElement: -> @
  
  showConnected: (connected)-> 
    if connected 
      @ideConn.addClass 'connected'
      @execButtons.find('.new-btn').removeClass 'disabled'
    else
      @ideConn.removeClass 'connected'
      @execButtons.find('.new-btn').addClass 'disabled'
    
  showRunPause: (running) ->
    if running
      @idePause.css display: 'inline-block'
      @ideRun.hide()
      @connected = no
    else
      @ideRun.css display: 'inline-block'
      @idePause.hide()     
      @connected = yes
      
  setStopSignActive: (active) ->
    if active then @stopSign.removeClass 'inactive'
    else @stopSign.addClass 'inactive'
      
  toggleConnection: -> 
    if not @codeExec
      @codeExec = new CodeExec @
    else 
      @codeExec.destroy()
      @codeExec = null
      @showConnected no
    @breakpointMgr.haveCodeExec @codeExec
  
  connClick: ->
    if @codeExec and not @ideConn.hasClass 'connected' 
      @toggleConnection()
    @toggleConnection()
    
  hideBreakpointPanel: -> @breakpointPanel.hide()
  hideStackPanel:      -> @stackPanel     .hide()
  
  setStack: (frames, refs) -> 
    @codeDisplay.setStack frames, refs
    @stackPanel .setStack frames, refs

  showFrame: (frame) -> 
    @codeDisplay.showFrame frame
    
  toggleBreakpoint: (file, line) -> @breakpointMgr.toggleBreakpoint file, line
  
  togglePanelBtn: (e, panel) ->
    switch
      when panel.floating then @dock.add    panel
      when panel.docked   then @dock.remove panel
      else panel.float $(e.target).offset()
    false
          
  # this is to fix .attr change in jQuery 1.6.0
  setClrAnyCheckbox: ($chk, checked) ->
    setTimeout (-> $chk.prop {checked}), 50
    
  changeBreakpoint: (breakpoint) -> 
    @breakpointMgr?.changeBreakpoint breakpoint
    @breakpointPanel.update()

  getVarPageEditor: ->
    for textEditor in atom.workspace.getTextEditors()
      if textEditor.getPath() is @varPagePath
        return textEditor
    null
    
  openVarPage: ->
    @state.varPageOpen = yes
    if not @getVarPageEditor()
      vpLine = @state.varPageLine   ? 0
      vpCol  = @state.varPageColumn ? 0
      atom.workspace.open @varPagePath, 
        split: 'right', initialLine: vpLine, initialColumn: vpCol
      return yes
    no
    
  saveCloseVarPage: (chgState = yes) ->
    if chgState then @state.varPageOpen = no
    if (textEditor = @getVarPageEditor())
      point = textEditor.getCursorBufferPosition()
      @state.varPageLine   = point.row
      @state.varPageColumn = point.column
      textEditor.saveAs @varPagePath
      textEditor.destroy()
      return yes
    no
      
  setupEvents: -> 
    @subs.push @on 'click', '.ide-conn', => 
      @connClick()
      false
    @subs.push @on 'click', '.ide-pause', => 
      if @connected then @codeExec?.pause()
      false
    @subs.push @on 'click', '.ide-run', => 
      if @connected then @codeExec?.run()
      false
    @subs.push @on 'click', '.ide-step-over', (e) => 
      if @connected then @codeExec?.step 'next'
      false
    @subs.push @on 'click', '.ide-step-in', (e) => 
      if @connected then @codeExec?.step 'in'
      false
    @subs.push @on 'click', '.ide-step-out', (e) => 
      if @connected then @codeExec?.step 'out'
      false
    @subs.push @on 'mousedown', '.ide-bp-btn', (e) =>
      @togglePanelBtn e, @breakpointPanel
      false
    @subs.push @on 'mousedown', '.ide-stack-btn', (e) =>
      @togglePanelBtn e, @stackPanel
      false
    @subs.push @on 'mousedown', '.ide-var-page-btn', (e) =>
      @openVarPage() or @saveCloseVarPage()
      false

  destroy: ->
    @saveCloseVarPage no
    @codeExec?.destroy()
    @breakpointMgr?.destroy()
    @breakpointPanel?.destroy()
    @stackPanel?.destroy()
    @varPage?.destroy()
    @dock.destroy()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    @remove()
