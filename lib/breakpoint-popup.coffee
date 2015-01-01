###
  lib/breakpoint-popup.coffee
###

{$, $$} = require 'atom-space-pen-views'

module.exports =
class BreakpointPopup
  
  @popup: ->
    @div class:'overlay from-top ide-view-popup native-key-bindings', tabindex: -1, =>
      @div class: 'ide-bp-header', 'Breakpoints'
      @div class: 'ide-bp-chkboxes', =>
        @label =>
          @input class:'ide-active-chk ide-bp-chk', type:"checkbox"
          @text 'Active'
        @label =>
          @input class:'ide-uncaught-chk ide-bp-chk', type:"checkbox"
          @text 'Uncaught Exc'
        @label =>
          @input class:'ide-caught-chk ide-bp-chk', type:"checkbox"
          @text 'Caught Exc'
      @div class: 'ide-bp-buttons', =>
        @div class: 'btn ide-popup-btn ide-bp-enable-all',  'Enable All'
        @div class: 'btn ide-popup-btn ide-bp-disable-all', 'Disable All'
        @div class: 'btn ide-popup-btn ide-bp-delete-all',  'Delete All'
      @div class: 'ide-bp-list', =>
        @div class: 'ide-bp-list-cover'
      
  constructor: (@breakpointMgr) ->
    @subs          = []
    @$popup        = $$ BreakpointPopup.popup
    @$activeChkBox = @$popup.find '.ide-active-chk'
    if @breakpointMgr.active then @$activeChkBox.attr checked: yes
    @$ideBpList = @$popup.find '.ide-bp-list'
    @$popup.appendTo $ '.workspace'
    @setupEvents()
    
  getBreakpoint: (e) ->
    dataBpId = $(e.target).closest('.ide-list-bp').attr 'data-bpid'
    @breakpointMgr.breakpoints[dataBpId]
    
  addBreakpoint: (breakpoint) ->
    file = breakpoint.file.replace /^[a-z]:\\/i, ''
    parts = file.split /\/|\\/g
    base  = parts.pop()
    path  = parts.join ' '
    @$ideBpList.prepend $newBp = $$ ->
      @div class:'ide-list-bp', =>
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
    @$popup.css(ofs).show()
    
  update: ->
    if @showing
      for id, breakpoint of @breakpointMgr.breakpoints
        $bp = @$popup.find '.ide-list-bp[data-bpid="' + id + '"]'
        if not $bp.length
          @addBreakpoint breakpoint
        else
          $enbldChk = $bp.find '.ide-list-chk'
          if breakpoint.enabled
               $enbldChk.attr checked: yes
          else $enbldChk.removeAttr 'checked'
      execPosition = @breakpointMgr.codeExec?.getExecPosition()
      @$popup.find('.ide-list-bp').each (i, e) =>
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
    @$popup.hide()
    @$popup.find('.ide-list-bp').remove()
    @showing = no
    
  setActive: (active) ->
    $cover = @$popup.find '.ide-bp-list-cover'
    if active then $cover.hide() else $cover.show()
    if active then @$activeChkBox.attr checked: yes
    else @$activeChkBox.removeAttr 'checked'
    
  activeClick: (e) ->
    @breakpointMgr.setActive $(e.target).is ':checked'
    
  setUncaughtExc: (e) ->
    set = $(e.target).is ':checked'
    if not @dontSetUncaughtExc
      @breakpointMgr.setUncaughtExc set
    
  setCaughtExc: (e) ->
    set = $(e.target).is ':checked'
    @breakpointMgr.setCaughtExc set
    if set 
      @dontSetUncaughtExc = yes 
      @$popup.find('.ide-uncaught-chk').attr checked: yes
      @dontSetUncaughtExc = no 

  setEnblBp: (e) -> 
    enbld = $(e.target).is ':checked'
    @getBreakpoint(e).setEnabled enbld; false
      
  showBp: (e) -> 
    if e.target.tagName isnt 'INPUT'
      @breakpointMgr.showBreakpoint @getBreakpoint e; false
    
  deleteBp: (e) -> @breakpointMgr.removeBreakpoint @getBreakpoint e; false
    
  setDelVisible: (e, vis) ->
    $(e.target).find('.ide-list-del')
               .css visibility: (if vis then 'visible' else 'hidden')
               
  setupEvents: ->
    @subs.push @$popup.on 'change', '.ide-active-chk',   (e) => @activeClick    e
    @subs.push @$popup.on 'change', '.ide-uncaught-chk', (e) => @setUncaughtExc e
    @subs.push @$popup.on 'change', '.ide-caught-chk',   (e) => @setCaughtExc   e
    
    @subs.push @$popup.on 'click', '.ide-bp-enable-all',  => @breakpointMgr.enableAll();  false
    @subs.push @$popup.on 'click', '.ide-bp-disable-all', => @breakpointMgr.disableAll(); false
    @subs.push @$popup.on 'click', '.ide-bp-delete-all',  => @breakpointMgr.deleteAll();  false
    
    @subs.push @$popup.on 'mouseenter', '.ide-list-bp', (e) => @setDelVisible e, yes
    @subs.push @$popup.on 'mouseleave', '.ide-list-bp', (e) => @setDelVisible e, no
    @subs.push @$popup.on 'mouseleave', '.ide-bp-list', (e) => @setDelVisible e, no
    
    @subs.push @$popup.on 'change', '.ide-list-chk', (e) => @setEnblBp e
    @subs.push @$popup.on 'click',  '.ide-list-bp',  (e) => @showBp e
    @subs.push @$popup.on 'click',  '.ide-list-del', (e) => @deleteBp e
    
    
    # @subs.push $('.workspace').on 'click mousedown focus blur keydown',  => 
    #   if @showing then @hide()
    
  destroy: ->
    @$popup.remove()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    
    