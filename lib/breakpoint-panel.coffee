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
      
  constructor: (@breakpointMgr) ->
    {@ideView}       = @breakpointMgr
    @subs            = []
    @$panel          = $$ BreakpointPanel.panel
    @$activeChkBox   = @$panel.find '.ide-active-chk'
    @$uncaughtChkBox = @$panel.find '.ide-uncaught-chk'
    @caughtChkBox    = @$panel.find '.ide-caught-chk'

    @$ideBpList = @$panel.find '.ide-view-panel-list'
    @$panel.appendTo $ '.workspace'
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
    if breakpoint.enabled then $chk.attr checked: yes
    
  show: (ofs) -> 
    @showing = yes
    @update()
    @$panel.css(ofs).show()
    @ideView.hideStackPanel()
    
  update: ->
    if @showing
      for id, breakpoint of @breakpointMgr.breakpoints
        $bp = @$panel.find '.ide-list-item[data-bpid="' + id + '"]'
        if not $bp.length
          @addBreakpoint breakpoint
        else
          $enbldChk = $bp.find '.ide-list-chk'
          if breakpoint.enabled
               $enbldChk.attr checked: yes
          else $enbldChk.removeAttr 'checked'
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
    @$panel.find('.ide-list-item').remove()
    @showing = no
    
  setActive: (active) ->
    $cover = @$panel.find '.ide-view-panel-list-cover'
    if active then $cover.hide() else $cover.show()
    if active then @$activeChkBox.prop 'checked', yes
    else @$activeChkBox.prop 'checked', no
    
  activeClick: (e) ->
    @breakpointMgr.setActive $(e.target).is ':checked'
    false
    
  setUncaughtExc: (e, set) ->
    set ?= $(e.target).is ':checked'
    if not @dontSetUncaughtExc
      @breakpointMgr.setUncaughtExc set
    false
    
  setCaughtExc: (e, set) ->
    set ?= $(e.target).is ':checked'
    @breakpointMgr.setCaughtExc set
    if set 
      @dontSetUncaughtExc = yes 
      @$panel.find('.ide-uncaught-chk').attr checked: yes
      @dontSetUncaughtExc = no 
    false

  setEnblBp: (e) -> 
    enbld = $(e.target).is ':checked'
    @getBreakpoint(e).setEnabled enbld; false
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
    @subs.push @$panel.on 'change', '.ide-active-chk',   (e) => @activeClick    e
    @subs.push @$panel.on 'change', '.ide-uncaught-chk', (e) => @setUncaughtExc e
    @subs.push @$panel.on 'change', '.ide-caught-chk',   (e) => @setCaughtExc   e
    
    @subs.push @$panel.on 'click', '.ide-bp-enable-all',  => @breakpointMgr.enableAll();  false
    @subs.push @$panel.on 'click', '.ide-bp-disable-all', => @breakpointMgr.disableAll(); false
    @subs.push @$panel.on 'click', '.ide-bp-delete-all',  => @breakpointMgr.deleteAll();  false
    
    @subs.push @$panel.on 'mouseenter', '.ide-list-item', (e) => @setDelVisible e, yes
    @subs.push @$panel.on 'mouseleave', '.ide-list-item', (e) => @setDelVisible e, no
    @subs.push @$panel.on 'mouseleave', '.ide-view-panel-list', (e) => @setDelVisible e, no
    
    @subs.push @$panel.on 'change', '.ide-list-chk', (e) => @setEnblBp e
    @subs.push @$panel.on 'click',  '.ide-list-item',  (e) => @showBp e
    @subs.push @$panel.on 'click',  '.ide-list-del', (e) => @deleteBp e
    
    # @subs.push $('.workspace').on 'click mousedown focus blur keydown',  => 
    #   if @showing then @hide()
    
  destroy: ->
    @$panel.remove()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    
    