class Capture
  before: ->
    window.$fixedels ||= jQuery("*").filter(-> jQuery(@).css("position") == "fixed" )
    window.$fixedels.css(position: "static")
    jQuery("html").css(overflow: "hidden")

  after: ->
    window.$fixedels.css(position: "fixed")
    jQuery("html").css(overflow: "visible")


class Selection extends Capture
  constructor: (@$el) ->
    @before()

    @$overlay = jQuery('<div>')
      .addClass('overlay')
      .css
          'position': 'fixed'
          'top': 0
          'left': 0
          'right': 0
          'bottom': 0
          'background-color': 'rgba(0,0,0,0.0)'
      .appendTo jQuery(document.body)
        
    @jcrop_api = $.Jcrop @$overlay, {
      onChange: @on_select_change,
      onSelect: @on_select_change,
      onDblClick: @_crop
    }
    jQuery('.jcrop-holder')
        .css 
            'position': 'fixed'
            'top': 0
            'left': 0
            'right': 0
            'bottom': 0
            'background-color': 'rgba(0,0,0,0.4)'

    @$actions = jQuery('<div><button class="button-4ye left cancel">取消</button><button class="button-4ye ok">确定</button></div>')
      .addClass('img4ye-actions')
      .css
        'position': 'fixed'
        'top': 0
        'left': 0
        'right': 0
        'bottom': 0
        'background-color': 'rgba(0,0,0,0.0)'
        'z-index': 9999999
        'display': 'none'
        'width': 100
        'height': 30
        'margin': 0
      .appendTo jQuery(document.body)

    @_bind()

  _bind: ->
    console.log '_bind'
    console.log @$actions
    console.log @jcrop_api
    @$actions.on 'click', '.cancel', @release

    @$actions.on 'click', '.ok', @_crop

    @$actions.on 'dblclick', ''

  release: () =>
    console.log 'release'
    @jcrop_api.release()
    @$actions.remove()
    @$overlay.remove()
    jQuery('.jcrop-holder').remove()

  _crop: =>
    console.log 'crop'
    @release()
    _.delay(@send_crop, 200)

  send_crop: =>
    console.log 'send crop'
    that = this
    chrome.runtime.sendMessage {task: "capture"}, (response) ->
      that.after()
      that.crop(response)

  actions_location:
    x: -100, y: 30

  on_select_change: (c) =>
    console.log c
    @selected = height: c.h, width: c.w, left: c.x, top: c.y
    @$actions
      .css
        'left': @selected.left + @selected.width + @actions_location.x
        'top': @selected.top + @selected.height + @actions_location.y
    if c.w > 0 and c.h > 0
      @$actions.show()
    else
      @$actions.hide()

  crop: (data)->
    return if !data
    new ImageCropper(data, @selected).exec()


class ImageCropper
  constructor: (@data, @selected)->
    @img    = new Image()
    @canvas = document.createElement("canvas")
    @ctx    = @canvas.getContext("2d")
    @bind()

  exec: -> 
    @img.src = @data

  bind: =>
    window.img = @img
    jQuery(@img).on "load", @bind_onload

  bind_onload: =>
    @canvas.width  = @selected.width
    @canvas.height = @selected.height
    
    @ctx.drawImage @img,
      @selected.left,
      @selected.top,
      @selected.width,
      @selected.height,
      0,
      0,
      @selected.width,
      @selected.height
    
    chrome.storage.local.set {'src': @canvas.toDataURL()}, ->
      window.open(window.extension_base_url + "edit.html", "_blank")

chrome.extension.onMessage.addListener (message, sender, resCallback) ->
  if message.task == 'fetchPageSize'
    pageSize = {
      scrollHeight: document.body.scrollHeight, scrollWidth: document.body.scrollWidth, clientWidth: document.documentElement.clientWidth, clientHeight: document.documentElement.clientHeight
    }
    resCallback(pageSize)
  else if message.task == 'scrollPage'
    window.scrollBy(message.x, message.y)
    pageSize = {}
    resCallback(pageSize)
  else if message.task == 'selection'
    window.selection = new Selection()
  else if message.task == 'fullpage'
    window.fullpage = new FullPage()
    window.fullpage.exec()
  else if message.task == "capture"
    chrome.tabs.captureVisibleTab null, {format: "png"}, respond
  else


class ImageBuffer
  constructor: (fullsize, @framesize, @callback) ->
    @canvas = document.createElement("canvas")
    @ctx    = @canvas.getContext("2d")

    @canvas.width  = fullsize.width
    @canvas.height = fullsize.height

  push: (meta, data)->
    $img = jQuery("<img>")

    $img.on "load", =>
      @ctx.drawImage($img[0],
                     meta.x,
                     meta.y,
                     @framesize.width,
                     @framesize.height)

      @callback(@canvas) if meta.done

    $img.attr("src", data)


class @FullPage
  constructor: -> #(@callback) ->
    @_init()

  _before: ->
    window.$fixedels ||= jQuery("*").filter ->
      jQuery(@).css("position") == "fixed"
    window.$fixedels.css(position: "static")
    jQuery("html").css(overflow: "hidden")

  _after: ->
    window.$fixedels.css(position: "fixed")
    jQuery("html").css(overflow: "visible")

  _init: ->
    @fullsize = height: jQuery(document).height(), width: jQuery(document).width()
    @framesize = height: window.innerHeight, width: window.innerWidth
    xs = (i for i in [0..@fullsize.width] by @framesize.width)
    ys = (i for i in [0..@fullsize.height] by @framesize.height)

    xs = xs.slice(1) if xs[xs.length - 1] == @fullsize.width
    ys = ys.slice(1) if ys[ys.length - 1] == @fullsize.height

    @frames = _.flatten([[{x: x, y: y} for x in xs] for y in ys])
    @buffer = new ImageBuffer(@fullsize, @framesize, @done)

  callback: (url) ->
    chrome.storage.local.set {'src': url}, ->
      window.open(window.extension_base_url + "edit.html", "_blank")

  done: =>
    @callback(@buffer.canvas.toDataURL())
    @_after()

  exec: ->
    @_before()
    @frame_itor(@frames)

  frame_itor: (frames) =>
    @frames = frames
    @scroll = frames[0]
    _.delay(@delay, 200)

  delay: =>
    if @scroll
      window.scrollTo(@scroll.x, @scroll.y)

      window.fullpage.meta = 
        done: window.fullpage.frames.length == 1
        x: window.scrollX
        y: window.scrollY

      _.delay(
        ->
          chrome.runtime.sendMessage {task: "capture"}, (response) ->
            window.fullpage.buffer.push(window.fullpage.meta, response)
            window.fullpage.frame_itor(window.fullpage.frames.slice(1))
        200
      )
    
jQuery ->
  chrome.runtime.sendMessage {task: "get_extension_base_url"}, (res) ->
    window.extension_base_url = res.url
