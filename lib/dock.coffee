###
  lib/dock.coffee
###

{$, $$} = require 'atom-space-pen-views'

module.exports =
class Dock
  
  @panel = ->
    @div class:'ide-dock-panel native-key-bindings', tabindex: -1

  constructor: (@ideView) ->
    @subs     = []
    @$panel   = $$ Dock.panel
    atom.workspace.addRightPanel item: @$panel
    
  add: (subPanel) ->
    subPanel.floating = no
    subPanel.docked  = yes
    @ideView.state[subPanel.name + 'Docked'] = yes
    subPanel.$panel.detach()
    subPanel.$panel.appendTo @$panel
    subPanel.$panel.removeClass 'overlay'
    subPanel.$panel.removeClass 'from-top'
    subPanel.$panel.addClass    'docked'
    @$panel.show()
    
  remove: (subPanel) ->
    subPanel.docked = no
    @ideView.state[subPanel.name + 'Docked'] = no
    subPanel.$panel.detach()
    subPanel.$panel.removeClass 'docked'
    subPanel.$panel.addClass    'overlay'
    subPanel.$panel.addClass    'from-top'
    if @$panel.children().length is 0
      @$panel.hide()

  destroy: -> @$panel.remove()