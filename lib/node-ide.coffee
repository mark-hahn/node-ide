
IdeView = require './ide-view'
{CompositeDisposable} = require 'atom'

module.exports =
  config:
    panelOnBottom:
      title: 'Place main IDE panel on bottom instead of top'
      type: 'boolean'
      default: false     
      
  activate: (@state) ->
    console.log 'state1', @state
    @subs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-workspace', 
      'node-ide:toggle': => @toggle()
      
    setInterval =>
      console.log 'state2', @state
    , 2000

  newIdePanel: ->
    @ideView = new IdeView @
    idePanelOpts = item: @ideView.getElement(), visible: false
    @idePanel = if atom.config.get 'node-ide.panelOnBottom'
         atom.workspace.addBottomPanel idePanelOpts
    else atom.workspace.addTopPanel    idePanelOpts
  
  toggle: ->
    if not @idePanel
      @newIdePanel()
    else
      @ideView.destroy()
      @idePanel.destroy()
      @idePanel = null
      
  serialize: -> 
    @state.breakpoints = @ideView.allBreakpointData()
    console.log 'state3', @state
    @state

  deactivate: ->
    @ideView.destroy()
    @idePanel.destroy()
    @subs.dispose()
  
