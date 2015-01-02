
{$,View} = require 'atom-space-pen-views'
{TextEditor} = require 'atom'

BreakpointMgr   = require './breakpoint-mgr'
CodeExec        = require './code-exec'
BreakpointPopup = require './breakpoint-popup'

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
      @div outlet: 'inspectorButtons', class: 'inspector-buttons', =>
        @div outlet:'breakBtn', class:'new-btn octicon ide-bp-btn ide-stop'

  initialize: (@nodeIde) ->
    {@state, @internalFileDir} = @nodeIde
    @subs = []
    process.nextTick =>
      @parent().addClass('ide-tool-panel').show()
      @setupEvents()
      @breakpointMgr   = new BreakpointMgr   @
      @breakpointPopup = new BreakpointPopup @breakpointMgr
      @showConnected no
      @toggleConnection()
      
      @breakpointPopup.setUncaughtExc null, @state.uncaughtExc
      @breakpointPopup.setCaughtExc   null, @state.caughtExc
      
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
      if @breakpointPopup.showing
        @breakpointPopup.hide()
      else
        @breakpointPopup.show $(e.target).offset()
      false
      
  allBreakpointData: -> @breakpointMgr.allBreakpointData()
      
  destroy: ->
    @codeExec?.destroy()
    @breakpointMgr?.destroy()
    @breakpointPopup?.destroy()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    @remove()
