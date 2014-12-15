# atom --remote-debugging-port=9222
# node --debug-brk 

###
  Navigate in your source files
  Set breakpoints (and specify trigger conditions)
  Step over, step in, step out, resume (continue)
  Inspect scopes, variables, object properties
  Hover your mouse over an expression in your source to display its value in a tooltip
  Edit variables and object properties
  Continue to location
  Break on exceptions
  Disable/enable all breakpoints
###

NodeIdeView = require './node-ide-view'
{CompositeDisposable} = require 'atom'

module.exports = NodeIde =
  nodeIdeView: null
  modalPanel: null
  subs: null

  activate: (state) ->
    @nodeIdeView = new NodeIdeView(state.nodeIdeViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @nodeIdeView.getElement(), visible: false)
    @subs = new CompositeDisposable

    # Register command that toggles this view
    @subs.add atom.commands.add 'atom-workspace', 'node-ide:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subs.dispose()
    @nodeIdeView.destroy()

  toggle: ->
    console.log 'NodeIde was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
