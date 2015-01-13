
fs          = require 'fs-plus'
pathUtil    = require 'path'
util        = require 'util'
IdeView     = require './ide-view'
Breakpoint  = require './breakpoint'

{CompositeDisposable} = require 'atom'

module.exports =
  config:
    enterInternalFiles:
      title: 'Step into Node internal functions like fs.js'
      type: 'boolean'
      default: yes     

  activate: (@state) ->
    @state.active      ?= yes
    @state.uncaughtExc ?= yes
    @state.caughtExc   ?= no
    @state.breakpoints ?= {}
    
    console.log 'node-ide activated', util.inspect @state, depth: null
    
    @breakpoints = {}
    for __, breakpoint of @state.breakpoints
      newBp = new Breakpoint @, breakpoint
      @breakpoints[newBp.id] = newBp

    projDir    = atom.project.getPaths()[0] ? fs.getHomeDirectory()
    nodeIdeDir = pathUtil.join projDir, '.node-ide'
    if not fs.existsSync nodeIdeDir
      fs.makeTreeSync nodeIdeDir
      process.nextTick -> 
        fs.writeFileSync pathUtil.join(nodeIdeDir, '.gitignore'), '**\n'
    @varPagePath     = pathUtil.join nodeIdeDir, 'node-ide-worksheet.nidews'
    @internalFileDir = pathUtil.join nodeIdeDir, 'internalFiles'
    fs.makeTreeSync @internalFileDir

    @subs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-workspace', 'node-ide:toggle': => @toggle()

  newIdePanel: ->
    @ideView = new IdeView @
    idePanelOpts = item: @ideView.getElement(), visible: false
    @idePanel = atom.workspace.addTopPanel idePanelOpts
  
  toggle: ->
    if not @idePanel
      @newIdePanel()
    else
      @ideView.destroy()
      @idePanel.destroy()
      @idePanel = null
      
  changeBreakpoint: (breakpoint) -> 
    @state.breakpoints[id] = breakpoint.getData()
    @ideView?.changeBreakpoint breakpoint
      
  serialize: -> 
    console.log 'node-ide serialize', util.inspect @state, depth: null
    @state

  deactivate: ->
    console.log 'node-ide deactivate'
    @ideView.destroy()
    @idePanel.destroy()
    @subs.dispose()
  

