#class View
  ##@delegate_to = (methods)->
    ##method <~ methods.forEach
    ##@::[method] = (...args)->
      ##value = @$el[method](...args)
      ##if value.constructor == jQuery && value.selector == @selector then @ else value

  ##@delegate_to <[on trigger show hide addClass appendTo remove css find]>

  #load_template: (template)->
    #TemplateLoader(template).exec(@)


#class Capture
  #before: ->
    #window.$fixedels ||= jQuery("*").filter(-> jQuery(@).css("position") == "fixed" )
    #window.$fixedels.css(position: "static")
    #jQuery("html").css(overflow: "hidden")

  #after: ->
    #window.$fixedels.css(position: "fixed")
    #jQuery("html").css(overflow: "visible")


#class Selection extends Capture
  ##constructor: (@callback)~>
  #constructor: (@$el) ->
    #@overlay   = new Overlay
    #@capturing = @binded = false
    #@reset_selection()
    #@bind()
    ##@before!
    ##@overlay.inject!

  #reset_selection: ->
    #@start = x: 0, y: 0
    #@selected = height: 16, width: 16, left: 0, top: 0

  #bind: ->
    #return if @binded

    #@overlay.on "mousedown", (event) ->
      #@reset_selection()
      #@capturing = true

      #@selected.top  = @start.y = event.pageY
      #@selected.left = @start.x = event.pageX

    #@overlay.on "mousemove", (event) ->
      #if @capturing
        #height = event.pageY - @start.y
        #width  = event.pageX - @start.x
        
        #@selected.top    = if height > 0 then @start.y else event.pageY
        #@selected.left   = if width  > 0 then @start.x else event.pageX
        #@selected.height = Math.abs(height)
        #@selected.width  = Math.abs(width)
        
        #@overlay.select(@selected)
    
    #@overlay.on "mouseup", (event) ->
      #@capturing = false
      #@selected.left = @selected.left - jQuery(document).scrollLeft()
      #@selected.top  = @selected.top  - jQuery(document).scrollTop()
      #@overlay.trigger("save")  
    
    #@overlay.on "save", ->
      #response <~ chrome.runtime.sendMessage task: "capture", _
      ##@overlay.remove!
      ##@after!
      #@crop(response)
    
    #@binded = true

  #crop: (data)->
    #return if !data
    #ImageCropper(data, @selected, @$el).exec()


#class ImageCropper
  #constructor: (@data, @selected, @callback)->
    #@img    = new Image
    #@canvas = document.createElement("canvas")
    #@ctx    = @canvas.getContext("2d")
    #@bind()

  #exec: -> 
    #@img.src = @data

  #bind: ->
    #@img.onload = ->
      #@canvas.width  = @selected.width
      #@canvas.height = @selected.height
      
      #@ctx.drawImage(@img,
                     #@selected.left,
                     #@selected.top,
                     #@selected.width,
                     #@selected.height,
                     #0,
                     #0,
                     #@selected.width,
                     #@selected.height)
      
      #@callback(@canvas.toDataURL()) if @callback

#class FullPage extends Capture
  #constructor: (@callback)->
    #@fullsize  = height: jQuery(document).height(), width: jQuery(document).width()
    #@framesize = height: window.innerHeight, width: window.innerWidth

    #xs = i for i in [0..@fullsize.width]
    #ys = i for i in [0..@fullsize.height]

    #xs = xs.slice(1) if xs[xs.length - 1] == @fullsize.width
    #ys = ys.slice(1) if ys[ys.length - 1] == @fullsize.height

    #@frames = _.flatten([[{x: x, y: y} for x in xs] for y in ys])
    #@buffer = ImageBuffer(@fullsize, @framesize, -> @done())
    #@exec()

  #done: -> 
    #@callback(@buffer.canvas.toDataURL())
    #@after()

  #exec: ->
    #@before()
 
    #frame_itor = (frames)->
      #scroll = frames[0]

      #delay = ->
        #window.scrollTo(scroll.x, scroll.y)

        #meta = {
          #done: frames.length == 1,
          #x: window.scrollX,
          #y: window.scrollY
        #}

        #_.delay(
          #->
            #response <~ chrome.runtime.sendMessage task: "capture", _
            #@buffer.push(meta, response)
            #frame_itor(frames.slice(1))
          #200)

      #_.delay(delay, 200)
      
    #frame_itor(@frames)

#class Choices extends View
  ##@delegate_to <[slideDown fadeOut]>

  #->
    #@load_template("choices")

    #@$fullpage  = @$el.find(".fullpage")
    #@$selection = @$el.find(".selection")

    ##@appendTo(document.body).slideDown()
    #@bind()

  #bind: ->
    ##dismiss = ["click", ~> @fadeOut ~> @remove()]

    ##jQuery(document).on ...dismiss

    #@$fullpage.on "click", (event)->
      #event.stopPropagation()
      #@remove()
      ##jQuery(document).off ...dismiss
      #FullPage(Popup)

    #@$selection.on "click", (event)->
      #event.stopPropagation()
      #@remove()
      ##jQuery(document).off ...dismiss
      #Selection(Popup)

#jQuery ->
  #chrome.runtime.onMessage.addListener (message) ->
    #switch message.task
      #when "capture"
        #Choices()
      #else
        #console.log "nothing"

console.log('content')
chrome.extension.onMessage.addListener (message, sender, resCallback) ->
  console.log(message)
  if message.act == 'fetchPageSize'
    console.log('fetchPageSize')
    pageSize = {
      scrollHeight: document.body.scrollHeight, scrollWidth: document.body.scrollWidth, clientWidth: document.documentElement.clientWidth, clientHeight: document.documentElement.clientHeight
    }
    resCallback(pageSize)
  else if message.act = 'scrollPage'
    console.log('scrollPage')
    window.scrollBy(message.x, message.y)
    pageSize = {}
    resCallback(pageSize)
  else
    console.log('other')
