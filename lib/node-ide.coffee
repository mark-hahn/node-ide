
V8 = require './v8-connect'

module.exports = NodeIde =
  config:
      targetHost:
        title: 'Target Host Address'
        type: 'string'
        default: 'localhost'
      targetPort:
        title: 'Target Host Port (1024-65535)'
        type: 'integer'
        default: 5858
        minimum: 1024
        maximum: 65535
  
  activate: (state) ->
    @v8conn = new V8 atom.config.get('node-ide.targetHost'), 
                     atom.config.get('node-ide.targetPort'), => 
                          
      @v8conn.onBreak (body) =>
        console.log 'activate break:', body
        
      @v8conn.onException (body) =>
        console.log 'activate exception:', body
        
      @v8conn.getScriptBreakpoints (res) =>
        console.log 'activate getScriptBreakpoints:', res
        @v8conn.step 1, =>
          @v8conn.resume()
    
  #   @nodeIdeView = new NodeIdeView(state.nodeIdeViewState)
  #   @modalPanel = atom.workspace.addModalPanel(item: @nodeIdeView.getElement(), visible: false)
  #   @subs = new CompositeDisposable
  # 
  #   # Register command that toggles this view
  #   @subs.add atom.commands.add 'atom-workspace', 'node-ide:toggle': => @toggle()
  # 
  # deactivate: ->
  #   @modalPanel.destroy()
  #   @subs.dispose()
  #   @nodeIdeView.destroy()
  # 
  # toggle: ->
  #   console.log 'NodeIde was toggled!'
  # 
  #   if @modalPanel.isVisible()
  #     @modalPanel.hide()
  #   else
  #     @modalPanel.show()

###
  # NodeIdeView = require './node-ide-view'
  # {CompositeDisposable} = require 'atom'

  # nodeIdeView: null
  # modalPanel: null
  # subs: null



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
###
