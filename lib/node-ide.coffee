
fs = require 'fs-plus'
pathUtil = require 'path'
IdeView = require './ide-view'
{CompositeDisposable} = require 'atom'

module.exports =
  config:
    panelOnBottom:
      title: 'Place main IDE panel on bottom instead of top'
      type: 'boolean'
      default: false  
         
    enterInternalFiles:
      title: 'Step into Node internal functions like fs.js'
      type: 'boolean'
      default: yes     
      
  activate: (@state) ->
    @internalFileDir = 
      pathUtil.join fs.getHomeDirectory(), '.nodeIde'
    fs.makeTreeSync @internalFileDir

    @subs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-workspace', 
      'node-ide:toggle': => @toggle()

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
    @ideView.allBreakpointData()

  deactivate: ->
    @ideView.destroy()
    @idePanel.destroy()
    @subs.dispose()
  

