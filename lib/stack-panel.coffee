###
  lib/stack-panel.coffee
###

{$, $$} = require 'atom-space-pen-views'
util    = require 'util'

module.exports =
class StackPanel
  
  @panel: ->
    @div class:'overlay from-top ide-view-panel native-key-bindings', tabindex: -1, =>
      @div class: 'ide-view-panel-header', 'Stack Frames'
      @div class: 'ide-view-panel-list'
      
  constructor: (@ideView) ->
    @subs          = []
    @$panel        = $$ StackPanel.panel
    @$ideFrameList = @$panel.find '.ide-view-panel-list'
    @$panel.appendTo $ '.workspace'
    @setupEvents()
    
  show: (ofs) -> 
    @showing = yes
    @$panel.css(ofs).show()
    @ideView.hideBreakpointPanel()
    
  hide: -> 
    @$panel.hide()
    @showing = no
    
  addFrame: (frame) ->
    parts = ///^ 
      \#\d+ .*?
      ([\w\.\[\]<>]+) \)? \( .*?
      (\S+)     \s
      line      \s (\d+) \s
      column    \s (\d+) \s
      \(position\s (\d+)\)
      $///.exec frame.text.replace /\r|\n/g, ' '
    if not parts
      console.log '\nnode-ide: frame text invalid', frame.index, frame.text.length, '\n', frame.text, '\n'
      @$ideFrameList.append $$ ->
        @div class:'ide-list-item', 'data-frameidx': frame.index, =>
          @div 'Frame ' + frame.index + ' parse error.'
      return
    console.log 'parts', frame.index, frame.text, parts
    
    func  = parts[1].replace ')(', '('
    file  = parts[2].replace /^[a-z]:\\/i, ''
    parts = file.split /\/|\\/g
    base  = parts.pop()
    path  = parts.join ' '
    @$ideFrameList.append $$ ->
      @div class:'ide-list-item', 'data-frameidx': frame.index, =>
        @span  class:'ide-list-func', func
        @span  class:'ide-list-path', path
        @div   class:'ide-list-base-line', =>
          @span class:'ide-list-base', base
          @span class:'ide-list-line', '(' + (frame.line+1) + ')'
  
  setStack: (@frames, @refs) ->
    @$ideFrameList.empty()
    for frame in frames then @addFrame frame
    
  setupEvents: ->
    @subs.push @$panel.on 'click', '.ide-view-panel-list', (e) => @showFrame e
    
    # @subs.push $('.workspace').on 'click mousedown focus blur keydown',  => 
    #   if @showing then @hide()
    
  destroy: ->
    @$panel.remove()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    
    