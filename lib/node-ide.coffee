
IdeView = require './ide-view'
{CompositeDisposable} = require 'atom'

module.exports = NodeIde =
  config:
    panelOnBottom:
      title: 'Place main IDE panel on bottom instead of top'
      type: 'boolean'
      default: false     
      
  activate: (@state) ->
    @subs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-workspace', 
      'node-ide:toggle': => @toggle()

  newIdePanel: ->
    @ideView = new IdeView
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

  deactivate: ->
    @ideView.destroy()
    @idePanel.destroy()
    @subs.dispose()
  
