class View
  constructor: ()->
    @

  load_template: (template)=>
    console.log 'View load template'
    @exec(@, template)

  exec: (view, name)->
    console.log 'View exec'
    @url = chrome.extension.getURL("#{name}.html")
    jQuery.ajax 
      async: false,
      type: "GET",
      url: @url,
      success: (html) ->
        console.log 'success'
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
    console.log 'inject'
    console.log @$el
    window.el = @$el
    @$el.css(height: jQuery(document).height(), width: jQuery(document).width())
      .appendTo(document.body)
      .show()
    console.log 'inject end'

  select: (selected)->
    console.log 'select'
    console.log selected
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
    console.log 'on'
    console.log event
    console.log callback
    @$el.on event, callback

  trigger: (event) ->
    @$el.trigger event

  remove: () ->
    console.log 'overlay remove()'
    @$el.remove()

  width: ->
    @$el.width()

  height: ->
    @$el.height()

class Capture
  before: ->
    console.log 'Capture before'
    window.$fixedels ||= jQuery("*").filter(-> jQuery(@).css("position") == "fixed" )
    window.$fixedels.css(position: "static")
    jQuery("html").css(overflow: "hidden")

  after: ->
    console.log 'Capture after'
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
    console.log 'selection constructor end'

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
      console.log 'mouseup'
      @capturing = false
      @selected.left = @selected.left - jQuery(document).scrollLeft()
      @selected.top  = @selected.top  - jQuery(document).scrollTop()
      @overlay.trigger("save")  
    
    @overlay.on "save", ->
      console.log 'on save'
      chrome.runtime.sendMessage {task: "capture"}, (response) ->
        console.log 'save'
        console.log response
        window.selection.overlay.remove()
        window.selection.after()
        #window.$fixedels.css(position: "fixed")
        #jQuery("html").css(overflow: "visible")
        window.selection.crop(response)
      console.log 'on save end'

    @binded = true

  save: (response) =>
    console.log 'save'
    console.log response
    @overlay.remove()
    @after()
    #window.$fixedels.css(position: "fixed")
    #jQuery("html").css(overflow: "visible")
    @crop(response)

  crop: (data)->
    console.log 'crop'
    console.log data
    return if !data
    new ImageCropper(data, @selected, @$el).exec()


class ImageCropper
  constructor: (@data, @selected, @callback)->
    @img    = new Image()
    @canvas = document.createElement("canvas")
    @ctx    = @canvas.getContext("2d")
    @bind()

  exec: -> 
    @img.src = @data

  bind: =>
    console.log @img
    window.img = @img
    jQuery(@img).on "load", @bind_onload

  bind_onload: =>
    console.log 'bind_onload'
    console.log @callback
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
    
    console.log 'before Popup'
    console.log @canvas.toDataURL()
    chrome.storage.local.set {'src': @canvas.toDataURL()}, ->
      console.log 'storage'
      window.open(window.extension_base_url + "edit.html", "_blank")
    #new @callback(@canvas.toDataURL()) if @callback

class Popup extends View
  constructor: (@src)->
    console.log 'Popup'
    console.log @src
    @load_template("uploader")

    console.log @$el
    @$img = @$el.find("img")
    @$submit = @$el.find(".submit")
    @$cancel = @$el.find(".cancel")

    @$el.appendTo(document.body)
    @bind()

  bind: ->
    that = this
    @$img.on "load", ->
      that.$el.css({"height": that.$img.height() + 64, "width": that.$img.width()})
      that.$el.slideDown()

    @$img.attr("src", @src)
    
    @$img.on "upload", ->
      console.log 'upload'
      that.$submit.text("正在上传....")

      #new ImageUploader(@src).exec ->
        #@$submit.text("上传完毕!").css("background-color", "green")

        #<~ @fadeOut
        #@remove()
    
    @$submit.on "click", ->
      console.log "submit click"
      that.$img.trigger("upload")

    @$cancel.on "click", ->
      console.log "cancel click"
      that.$el.fadeOut ANIMATE_DURATION, ->
        that.$el.remove()
      #console.log "cancel click"
      #@$img.
      ##<~ @fadeOut
      ##@remove()

console.log('content')
chrome.extension.onMessage.addListener (message, sender, resCallback) ->
  console.log(message)
  if message.task == 'fetchPageSize'
    console.log('fetchPageSize')
    pageSize = {
      scrollHeight: document.body.scrollHeight, scrollWidth: document.body.scrollWidth, clientWidth: document.documentElement.clientWidth, clientHeight: document.documentElement.clientHeight
    }
    resCallback(pageSize)
  else if message.task == 'scrollPage'
    console.log('scrollPage')
    window.scrollBy(message.x, message.y)
    pageSize = {}
    resCallback(pageSize)
  else if message.task == 'selection'
    console.log 'page selection'
    window.selection = new Selection(Popup)
  else if message.task == "capture"
    console.log 'task capture'
    chrome.tabs.captureVisibleTab null, {format: "png"}, respond
  else
    console.log('other')

jQuery ->
  console.log 'page loaded'
  chrome.runtime.sendMessage {task: "get_extension_base_url"}, (res) ->
    console.log 'respond get_extension_base_url'
    console.log res.url
    window.extension_base_url = res.url
