
IdeView = require './ide-view'
{CompositeDisposable} = require 'atom'

module.exports = NodeIde =
  config:
    panelOnBottom:
      title: 'Place main IDE panel on bottom instead of top'
      type: 'boolean'
      default: false     
      
  nodeIdeView: null
  modalPanel: null
  subs: null
  
  activate: (@state) ->
    console.log 'activate'
    @subs = new CompositeDisposable
    @subs.add atom.commands.add 'atom-workspace', 'node-ide:toggle': => @toggle()
    @newIdePanel()

  newIdePanel: ->  
    @ideView = new IdeView @
    idePanelOpts = item: @ideView.getElement(), visible: false
    @idePanel = if atom.config.get 'node-ide.panelOnBottom'
         atom.workspace.addBottomPanel idePanelOpts
    else atom.workspace.addTopPanel    idePanelOpts
    
  deactivate: ->
    @ideView.destroy()
    @idePanel.destroy()
    @subs.dispose()
  
  toggle: ->
    if @idePanel.isVisible()
      @ideView.destroy()
      @idePanel.destroy()
      # @idePanel.hide()
    else
      # @idePanel.show()
      @newIdePanel()


###
  "activationCommands": {
    "atom-workspace": "node-ide:toggle"
  },

  node --debug-brk 
  atom --remote-debugging-port=9222

  Navigate in your source files
  Set breakpoints (and specify trigger conditions)
  Step over, step in, step out, resume (continue)
  Inspect scopes, variables, object properties
  Hover your mouse over an expression in your source to display its value in a tooltip
  Edit variables and object properties
  Continue to location
  Break on exceptions
  Disable/enable all breakpoints
  
  @v8conn = new V8()
  @v8conn.connect '127.0.0.1', '5858', (err) ->
    if err 
      console.log 'activate connect err', err
      return
    console.log 'activate connect', body
    @v8conn.onBreak (body) =>
      console.log 'activate break:', body
      @v8conn.getScriptBreakpoints (err, res) =>
        console.log 'activate getScriptBreakpoints3:', res
        @v8conn.destroy -> 
          console.log 'activate destroyed'
    @v8conn.onException (body) =>
      console.log 'activate exception:', body
    @v8conn.onEnd =>
      console.log 'activate end'
    @v8conn.onClose (body) =>
      console.log 'activate close:', body
    @v8conn.getScriptBreakpoints (err, res) =>
      console.log 'activate getScriptBreakpoints1:', res
      @v8conn.setScriptBreakpoint \
          'C:\\Users\\Administrator\\.atom\\packages\\node-ide\\test.js', 12, (err, res) =>
        console.log 'activate setScriptBreakpoint:', res
        @v8conn.getScriptBreakpoints (err, res) =>
          console.log 'activate getScriptBreakpoints2:', res
          @v8conn.resume()

###
