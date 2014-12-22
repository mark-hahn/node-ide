
{View}    = require 'atom-space-pen-views'

CodeExec     = require './code-exec'
CodeDisplay  = require './code-display'

module.exports =
class IdeView extends View
  
  @content: ->
    @div class: 'node-ide', =>
      @div class: 'logo', "Node-IDE"
      @div outlet:'idePause', class:'new-btn ide-pause'
      @div outlet:'ideRun',   class:'new-btn ide-run'
      @div outlet:'ideOver',  class:'new-btn ide-step-over'
      @div outlet:'ideIn',    class:'new-btn ide-step-in'
      @div outlet:'ideOut',   class:'new-btn ide-step-out'

  initialize: (nodeIDE) ->
    @subs = []
    process.nextTick =>
      @parent().addClass('ide-tool-panel').show()
      @setupEvents()
      @codeExec    = new CodeExec @
      @codeDisplay = new CodeDisplay @
      @codeExec.setCodeDisplay @codeDisplay
      @codeDisplay.setCodeExec @codeExec
              
  getElement: -> @
  
  showRunPause: (running) ->
    if running
      @idePause.css display: 'inline-block'
      @ideRun.hide()
    else
      @ideRun.css display: 'inline-block'
      @idePause.hide()      
  
  setupEvents: ->
    @subs.push @on 'click', '.ide-pause',         => @codeExec.pause();     false
    @subs.push @on 'click', '.ide-run',           => @codeExec.run();       false
    @subs.push @on 'click', '.ide-step-over', (e) => @codeExec.step 'next'; false
    @subs.push @on 'click', '.ide-step-in',   (e) => @codeExec.step 'in';   false
    @subs.push @on 'click', '.ide-step-out',  (e) => @codeExec.step 'out';  false
      
  serialize: ->

  destroy: ->
    @codeDisplay.destroy()
    @codeExec.destroy()
    @remove()

