
{View}    = require 'atom-space-pen-views'

CodeExec     = require './code-exec'
CodeDisplay  = require './code-display'

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
    process.nextTick =>
      @parent().addClass('ide-tool-panel').show()
      @setupEvents()
      @codeExec    = new CodeExec @
      @codeDisplay = new CodeDisplay @
      @codeExec.setCodeDisplay @codeDisplay
      @codeDisplay.setCodeExec @codeExec
              
  getElement: -> @
  
  showRunPause: ->
    if @running
      @idePause.css display: 'inline-block'
      @idePlay.hide()
    else
      @idePlay.css display: 'inline-block'
      @idePause.hide()      
  
  setupEvents: ->
    @subs.push @on 'click', '.ide-step-over', (e) => @codeExec.step 'next'
    @subs.push @on 'click', '.ide-play',          =>
      console.log 'node-ide: ide-play'
      @codeExec.run()
      
  serialize: ->

  destroy: ->
    @codeDisplay.destroy()
    @codeExec.destroy()
    @remove()

