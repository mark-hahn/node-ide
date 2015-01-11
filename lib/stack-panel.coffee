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
    
  clear: -> @$ideFrameList.empty()
    
  addFrame: (frame) ->
    @$ideFrameList.append $item = $$ ->
      @div class:'ide-list-item', 'data-frameidx': frame.index, =>
        @span  class:'ide-list-func', frame.func
        @span  class:'ide-list-path', frame.path
        @div   class:'ide-list-base-line', =>
          @span class:'ide-list-base', frame.base
          @span class:'ide-list-line', '(' + (frame.line+1) + ')'
    $item
  
  setStack: (@frames, @refs) ->
    @$ideFrameList.empty()
    {curExecPosition, curFramePosition} = @ideView.getCurPositions()
    for frame in frames 
      parts = ///^ 
        \#\d+ .*?
        ([\w\.\[\]<>]+) \)? \( .*?
        (\S+)      \s
        line       \s (\d+) \s
        column     \s (\d+) \s
        \(position \s (\d+) \)
        $///.exec frame.text.replace /\r|\n/g, ' '
      if not parts
        console.log '\nnode-ide: frame text invalid', 
                      frame.index, frame.text.length, '\n', frame.text, '\n'
        @$ideFrameList.append $item = $$ ->
          @div class:'ide-list-item', 'data-frameidx': frame.index, =>
            @div 'Frame ' + frame.index + ' parse error.'
        continue
      frame.func  = parts[1].replace ')(', '('
      frame.file  = parts[2]
      fileParts   = frame.file.replace(/^[a-z]:\\/i, '').split /\/|\\/g
      frame.base  = fileParts.pop()
      frame.path  = fileParts.join ' '
      $item = @addFrame frame
      if (frame.file is curExecPosition?.file and
          frame.line is curExecPosition?.line) or
         (frame.file is curFramePosition?.file and
          frame.line is curFramePosition?.line)
        @selectFrame null, $item
    null
      
  selectFrame: (e, $item) ->
    if e then $item = $(e.target).closest '.ide-list-item'
    @$panel.find('.ide-list-item').removeClass 'selected'
    $item.addClass 'selected'
    if e  
      frame = @frames[+$item.attr('data-frameidx')]
      @ideView.showCurExecLine
        file:   frame.file
        line:   frame.line
        column: frame.column
      , yes
      
  setupEvents: ->
    @subs.push @$panel.on 'click', '.ide-view-panel-list', (e) => @selectFrame e
    
    # @subs.push $('.workspace').on 'click mousedown focus blur keydown',  => 
    #   if @showing then @hide()
    
  destroy: ->
    @$panel.remove()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    
    