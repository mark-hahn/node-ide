
{View}    = require 'atom-space-pen-views'

CodeExec     = require './code-exec'
CodeDisplay  = require './code-display'

module.exports =
class IdeView extends View
  
  @content: ->
    @div class: 'node-ide', =>
      @div class: 'logo', "Node-IDE"
      @div outlet:'ideConn',  class:'new-btn octicon ide-conn'
      @div outlet:'idePause', class:'new-btn octicon ide-pause'
      @div outlet:'ideRun',   class:'new-btn octicon ide-run'
      @div outlet:'ideOver',  class:'new-btn octicon ide-step-over'
      @div outlet:'ideIn',    class:'new-btn octicon ide-step-in'
      @div outlet:'ideOut',   class:'new-btn octicon ide-step-out'

  initialize: ->
    @subs = []
    process.nextTick =>
      @parent().addClass('ide-tool-panel').show()
      @setupEvents()
      @showConnected no
      @toggleConnection()
      
  getElement: -> @
  
  showConnected: (connected)-> 
    if connected then @ideConn.addClass    'connected'    
    else              @ideConn.removeClass 'connected'    
  
  showRunPause: (running) ->
    if running
      @idePause.css display: 'inline-block'
      @ideRun.hide()
    else
      @ideRun.css display: 'inline-block'
      @idePause.hide()     
      
  toggleConnection: -> 
    if not @codeExec
      @codeExec    = new CodeExec @
      @codeDisplay = new CodeDisplay @
      @codeExec.setCodeDisplay @codeDisplay
      @codeDisplay.setCodeExec @codeExec  
    else 
      @codeExec.destroy()
      @codeDisplay.destroy()
      @codeExec = @codeDisplay = null
      @showConnected no
    console.log 'toggleConnection', @codeExec?
    
  connClick: ->
    if @codeExec and not @ideConn.hasClass 'connected' 
      @toggleConnection()
    @toggleConnection()
      
  setupEvents: ->
    @subs.push @on 'click', '.ide-conn',          => @connClick();          false
    @subs.push @on 'click', '.ide-pause',         => @codeExec.pause();     false
    @subs.push @on 'click', '.ide-run',           => @codeExec.run();       false
    @subs.push @on 'click', '.ide-step-over', (e) => @codeExec.step 'next'; false
    @subs.push @on 'click', '.ide-step-in',   (e) => @codeExec.step 'in';   false
    @subs.push @on 'click', '.ide-step-out',  (e) => @codeExec.step 'out';  false
      
  serialize: ->

  destroy: ->
    @codeDisplay?.destroy()
    @codeExec?.destroy()
    @remove()

