class View
  constructor: ()->
    @

  load_template: (template)=>
    @exec(@, template)

  exec: (view, name)->
    @url = chrome.extension.getURL("#{name}.html")
    jQuery.ajax 
      async: false,
      type: "GET",
      url: @url,
      success: (html) ->
        window.overlay = view
        window.html = html
        view.$el = jQuery(html)


class Overlay extends View
  constructor: ->
    @nobg = "background-color": "rgba(0,0,0,0)"

    @load_template("overlay")

    @$tl = @$el.find(".tl")
    @$tr = @$el.find(".tr")
    @$br = @$el.find(".br")
    @$bl = @$el.find(".bl")

  inject: ->
    window.el = @$el
    @$el.css(height: jQuery(document).height(), width: jQuery(document).width())
      .appendTo(document.body)
      .show()

  select: (selected)->
    window.selected = selected
    @$el.css(@nobg)

    @$tl.css
      width:  selected.left + selected.width,
      height: selected.top

    @$tr.css
      width:  @width() - (selected.left + selected.width),
      height: selected.top + selected.height

    @$br.css
      width:  @width() - selected.left,
      height: @height() - (selected.top + selected.height)

    @$bl.css
      width:  selected.left,
      height: @height() - selected.top

  on: (event, callback) ->
    @$el.on event, callback

  trigger: (event) ->
    @$el.trigger event

  remove: () ->
    @$el.remove()

  width: ->
    @$el.width()

  height: ->
    @$el.height()

class Capture
  before: ->
    window.$fixedels ||= jQuery("*").filter(-> jQuery(@).css("position") == "fixed" )
    window.$fixedels.css(position: "static")
    jQuery("html").css(overflow: "hidden")

  after: ->
    window.$fixedels.css(position: "fixed")
    jQuery("html").css(overflow: "visible")


class Selection extends Capture
  #constructor: (@callback)~>
  constructor: (@$el) ->
    @overlay   = new Overlay()
    @capturing = @binded = false
    @reset_selection()
    @bind()
    @before()
    @overlay.inject()

  reset_selection: ->
    @start = x: 0, y: 0
    @selected = height: 16, width: 16, left: 0, top: 0

  bind: ->
    return if @binded

    @overlay.on "mousedown", (event) =>
      @reset_selection()
      @capturing = true

      @selected.top  = @start.y = event.pageY
      @selected.left = @start.x = event.pageX

    @overlay.on "mousemove", (event) =>
      if @capturing
        height = event.pageY - @start.y
        width  = event.pageX - @start.x
        
        @selected.top    = if height > 0 then @start.y else event.pageY
        @selected.left   = if width  > 0 then @start.x else event.pageX
        @selected.height = Math.abs(height)
        @selected.width  = Math.abs(width)
        
        @overlay.select(@selected)
    
    @overlay.on "mouseup", (event) =>
      @capturing = false
      @selected.left = @selected.left - jQuery(document).scrollLeft()
      @selected.top  = @selected.top  - jQuery(document).scrollTop()
      @overlay.trigger("save")  
    
    @overlay.on "save", ->
      chrome.runtime.sendMessage {task: "capture"}, (response) ->
        window.selection.overlay.remove()
        window.selection.after()
        window.selection.crop(response)

    @binded = true

  save: (response) =>
    @overlay.remove()
    @after()
    @crop(response)

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
    #@_before()
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
    
#@flatten = (a) ->
  #if a.length is 0 then return []
  #a.reduce (lhs, rhs) -> lhs.concat rhs

#@isFunction = (f) ->
  #if typeof f is 'function'
    #true
  #else
    #false

jQuery ->
  chrome.runtime.sendMessage {task: "get_extension_base_url"}, (res) ->
    window.extension_base_url = res.url
