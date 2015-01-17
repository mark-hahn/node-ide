###
  lib/breakpoint-panel.coffee
###

{$, $$} = require 'atom-space-pen-views'

module.exports =
class BreakpointPanel
  
  @panel: ->
    @div class:'overlay from-top ide-view-panel native-key-bindings', tabindex: -1, =>
      @div class: 'ide-view-panel-header', 'Breakpoints'
      @div class: 'ide-bp-chkboxes', =>
        @label =>
          @input class:'ide-active-chk ide-bp-chk', type:"checkbox", checked: yes
          @text 'Active'
        @label =>
          @input class:'ide-uncaught-chk ide-bp-chk', type:"checkbox", checked: yes
          @text 'Uncaught Exc'
        @label =>
          @input class:'ide-caught-chk ide-bp-chk', type:"checkbox"
          @text 'Caught Exc'
      @div class: 'ide-bp-buttons', =>
        @div class: 'btn ide-panel-btn ide-bp-enable-all',  'Enable All'
        @div class: 'btn ide-panel-btn ide-bp-disable-all', 'Disable All'
        @div class: 'btn ide-panel-btn ide-bp-delete-all',  'Delete All'
      @div class: 'ide-view-panel-list', =>
        @div class: 'ide-view-panel-list-cover'

  constructor: (@ideView) ->
    {@breakpointMgr} = @ideView
    @name            = 'breakpointPanel'
    @subs            = []
    @$panel          = $$ BreakpointPanel.panel
    @$activeChkBox   = @$panel.find '.ide-active-chk'
    @$uncaughtChkBox = @$panel.find '.ide-uncaught-chk'
    @$caughtChkBox   = @$panel.find '.ide-caught-chk'

    @$ideBpList = @$panel.find '.ide-view-panel-list'
    @setupEvents()
    
  getBreakpoint: (e) ->
    dataBpId = $(e.target).closest('.ide-list-item').attr 'data-bpid'
    @breakpointMgr.breakpoints[dataBpId]
    
  addBreakpoint: (breakpoint) ->
    file = breakpoint.file.replace /^[a-z]:\\/i, ''
    parts = file.split /\/|\\/g
    base  = parts.pop()
    path  = parts.join ' '
    @$ideBpList.prepend $newBp = $$ ->
      @div class:'ide-list-item', =>
        @input class:'ide-list-chk', type:'checkbox'
        @div   class:'ide-list-del', 'X'
        @span  class:'ide-list-path', path
        @div   class:'ide-list-base-line', =>
          @span class:'ide-list-base', base
          @span class:'ide-list-line', '(' + (breakpoint.line+1) + ')'
    $newBp.attr 'data-bpid': breakpoint.id
    $chk = $newBp.find '.ide-list-chk'
    if breakpoint.enabled then $chk.prop checked: yes
    
  float: (ofs) -> 
    @floating = yes
    @$panel.appendTo $ '.workspace'
    @update()
    @$panel.css(ofs).show()
    if @ideView.stackPanel.floating
      @ideView.hideStackPanel()
    
  update: ->
    if @floating or @docked
      for id, breakpoint of @breakpointMgr.breakpoints
        $bp = @$panel.find '.ide-list-item[data-bpid="' + id + '"]'
        if not $bp.length
          @addBreakpoint breakpoint
        else
          $enbldChk = $bp.find '.ide-list-chk'
          $enbldChk.prop checked: breakpoint.enabled
      execPosition = @breakpointMgr.codeExec?.getExecPosition()
      @$panel.find('.ide-list-item').each (i, e) =>
        $bp = $ e
        bpid = $bp.attr 'data-bpid'
        breakpoint = @breakpointMgr.breakpoints[bpid]
        if not breakpoint 
          $bp.remove()
        else if execPosition and
                breakpoint.file is execPosition.file and
                breakpoint.line is execPosition.line
          $bp.addClass 'exec-pos'
        else
          $bp.removeClass 'exec-pos'
        
  hide: -> 
    @$panel.hide()
    @$panel.find('.ide-list-item').detach()
    @floating = no
    
  setActive: (active) ->
    @ideView.setStopSignActive active
    @ideView.setClrAnyCheckbox @$activeChkBox, active

  activeClick: ->
    @breakpointMgr.setActive @$activeChkBox.is ':checked'
    false
    
  setUncaughtExc: (set) ->
    set ?= @$uncaughtChkBox.is ':checked'
    @breakpointMgr.setUncaughtExc set
    @ideView.setClrAnyCheckbox @$uncaughtChkBox, set
    if not set then @setCaughtExc no
    false
    
  setCaughtExc: (set) ->
    set ?= @$caughtChkBox.is ':checked'
    @breakpointMgr.setCaughtExc set
    @ideView.setClrAnyCheckbox @$caughtChkBox, set
    if set then @setUncaughtExc yes
    false

  setEnblBp: (e) -> 
    enbld = $(e.target).is ':checked'
    if enbld then @breakpointMgr.setActive yes
    breakpoint = @getBreakpoint e 
    breakpoint.setEnabled enbld
    # the following is to fix a problem caused by jQuery 1.6 .attr
    id   = breakpoint.id
    $chk = @$panel.find '.ide-list-item[data-bpid="' + id + '"] .ide-list-chk'
    @ideView.setClrAnyCheckbox $chk, enbld
    false

  showBp: (e) -> 
    if e.target.tagName isnt 'INPUT'
      @breakpointMgr.showBreakpoint @getBreakpoint e; false
    false
    
  deleteBp: (e) -> @breakpointMgr.removeBreakpoint @getBreakpoint e; false
    
  setDelVisible: (e, vis) ->
    $(e.target).find('.ide-list-del')
               .css visibility: (if vis then 'visible' else 'hidden')
    false
  
  setupEvents: ->
    @subs.push @$panel.on 'change', '.ide-active-chk',   (e) => @activeClick()
    @subs.push @$panel.on 'change', '.ide-uncaught-chk', (e) => @setUncaughtExc()
    @subs.push @$panel.on 'change', '.ide-caught-chk',   (e) => @setCaughtExc()
    
    @subs.push @$panel.on 'click', '.ide-bp-enable-all',  => @breakpointMgr.enableAll();  false
    @subs.push @$panel.on 'click', '.ide-bp-disable-all', => @breakpointMgr.disableAll(); false
    @subs.push @$panel.on 'click', '.ide-bp-delete-all',  => @breakpointMgr.deleteAll();  false
    
    @subs.push @$panel.on 'mouseenter', '.ide-list-item',       (e) => @setDelVisible e, yes
    @subs.push @$panel.on 'mouseleave', '.ide-list-item',       (e) => @setDelVisible e, no
    @subs.push @$panel.on 'mouseleave', '.ide-view-panel-list', (e) => @setDelVisible e, no
    
    @subs.push @$panel.on 'change', '.ide-list-chk',  (e) => @setEnblBp e
    @subs.push @$panel.on 'click',  '.ide-list-item', (e) => @showBp    e
    @subs.push @$panel.on 'click',  '.ide-list-del',  (e) => @deleteBp  e
    
    @subs.push $('.workspace').on 'mousedown focus blur keydown',  (e) => 
      if @floating then @hide()
    
  destroy: ->
    @$panel.remove()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    
    