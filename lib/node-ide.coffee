
V8 = require './v8-connection'

module.exports = NodeIde =
  
  activate: (state) ->
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
          
          
          # @v8conn.destroy ->
          #   console.log 'activate disconnected'
    
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
