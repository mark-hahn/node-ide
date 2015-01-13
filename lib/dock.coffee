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
    atom.workspace.addRightPanel item: @$panel, visible: false
    
  add: (subPanel) ->
    subPanel.showing = no
    subPanel.docked  = yes
    subPanel.$panel.remove()
    subPanel.$panel.appendTo @$panel
    subPanel.$panel.removeClass 'overlay'
    subPanel.$panel.removeClass 'from-top'
    subPanel.$panel.addClass    'docked'
    @$panel.parent().show()
    @$panel.show()
    
  remove: (subPanel) ->
    subPanel.docked = no
    subPanel.$panel.remove()
    subPanel.$panel.removeClass 'docked'
    subPanel.$panel.addClass    'overlay'
    subPanel.$panel.addClass    'from-top'
    if @$panel.children().length is 0
      @$panel.parent().hide()
      @$panel.hide()
