
{$,View} = require 'atom-space-pen-views'
{TextEditor} = require 'atom'

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

  initialize: (@nodeIde) ->
    {@state, @internalFileDir} = @nodeIde
    @subs = []
    process.nextTick =>
      @parent().addClass('ide-tool-panel').show()
      @setupEvents()
      @breakpointMgr   = new BreakpointMgr   @
      @codeDisplay     = new CodeDisplay     @
      @breakpointPanel = new BreakpointPanel @breakpointMgr
      @stackPanel      = new StackPanel      @
      
      @showConnected no
      @toggleConnection()
      
      @breakpointMgr.setCodeDisplay @codeDisplay
      @breakpointPanel.setUncaughtExc null, @state.uncaughtExc
      @breakpointPanel.setCaughtExc   null, @state.caughtExc
      
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
    @breakpointMgr.setCodeExec @codeExec
  
  connClick: ->
    if @codeExec and not @ideConn.hasClass 'connected' 
      @toggleConnection()
    @toggleConnection()
    
  hideBreakpointPanel:     -> @breakpointPanel.hide()
  hideStackPanel:          -> @stackPanel     .hide()
  
  setStack: (frames, refs) -> @stackPanel.setStack frames, refs
      
  showCurExecLine: (position, isFrame = yes) -> 
    @codeDisplay.showCurExecLine position, isFrame
    
  getCurPositions: -> 
    curExecPosition:  @codeDisplay.curExecPosition
    curFramePosition: @codeDisplay.curFramePosition
    
  toggleBreakpoint: (file, line) -> @breakpointMgr.toggleBreakpoint file, line
    
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
      
    @subs.push @on 'click', '.ide-bp-btn', (e) =>
      if @breakpointPanel.showing
        @breakpointPanel.hide()
      else
        @breakpointPanel.show $(e.target).offset()
      false
      
    @subs.push @on 'click', '.ide-stack-btn', (e) =>
      if @stackPanel.showing
        @stackPanel.hide()
      else
        @stackPanel.show $(e.target).offset()
      false
      
  allBreakpointData: -> @breakpointMgr.allBreakpointData()
      
  destroy: ->
    @codeExec?.destroy()
    @breakpointMgr?.destroy()
    @breakpointPanel?.destroy()
    @stackPanel?.destroy()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    @remove()
