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
    @name          = 'stackPanel'
    @$panel        = $$ StackPanel.panel
    @$ideFrameList = @$panel.find '.ide-view-panel-list'
    @$panel.appendTo $ '.workspace'
    @setupEvents()
    
  float: (ofs) -> 
    @floating = yes
    @$panel.css(ofs).show()
    if @ideView.breakpointPanel.floating
      @ideView.hideBreakpointPanel()
    @$panel.appendTo $ '.workspace'
    
  hide: -> 
    @$panel.hide()
    @floating = @docked = no
    
  clear: -> @$ideFrameList.empty()
    
  addFrame: (frame) ->
    @$ideFrameList.append $item = $$ ->
      @div class:'ide-list-item', 'data-frameidx': frame.index, =>
        @span  class:'ide-list-func', frame.func + ';'
        @span  class:'ide-list-path', frame.path
        @div   class:'ide-list-base-line', =>
          @span class:'ide-list-base', frame.base
          @span class:'ide-list-line', '(' + (frame.line+1) + ')'
    $item
  
  setStack: (@frames, @refs) ->
    @$ideFrameList.empty()
    for frame, idx in @frames 
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
      @addFrame frame
    @selectedFrame ?= @frames[0]
    frameIdx = @selectedFrame.index
    $frameItem = @$panel.find '.ide-list-item[data-frameidx="' + frameIdx + '"]'
    @showSelectedFrame frame, $frameItem

  showSelectedFrame: (frame, $frameItem) ->
    @$panel.find('.ide-list-item').removeClass 'selected'
    $frameItem.addClass 'selected'
    @ideView.showFrame frame

  frameClick: (e) ->
    $frameItem =  $(e.target).closest '.ide-list-item'
    frameIdx = $frameItem.attr 'data-frameidx'
    frame = @frames[frameIdx]
    @selectedFrame = frame
    @showSelectedFrame frame, $frameItem
    false

  setupEvents: ->
    @subs.push @$panel.on 'click', '.ide-view-panel-list', (e) => @frameClick e
    @subs.push $('.workspace').on 'click focus blur keydown',  (e) => 
      if @floating then @hide()
    
  destroy: ->
    @$panel.remove()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    
    