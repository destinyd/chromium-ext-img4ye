jQuery ->
  console.log 'loaded'
# HOST = "http://collect.4ye.me"
HOST = "http://done-list.local.realityandapp.com:3000"
ANIMATE_DURATION = 200

delay = (ms, func) -> setTimeout func, msg

show_loading_after = ($dom, info)->
  l = new Loading()
  l.show_after $dom, info
  l

class Auth
  constructor: (@$el, @popup)->
    @$signin_btn = @$el.find('.signin')

  go: (func)->
    jQuery.ajax "#{HOST}/api/auth_check"
      .done (res)=>
        # 验证通过，显示用户信息
        console.log res
        #avatar = res.avatar
        name = res.name
        #jQuery('.user-info .avatar').css 'background-image', "url(#{avatar})"
        jQuery('.user-info .name').text name
        # jQuery('.user-info').fadeIn(ANIMATE_DURATION)
        jQuery('.user-info').fadeIn(ANIMATE_DURATION)

        # 绑定按钮操作
        @popup.show_info()

      .fail (err)=>
        # 验证未通过，显示登录按钮
        # @$el.fadeIn(ANIMATE_DURATION)
        console.log 'fail'
        @$el.show()

      .always =>
        func()

class Popup
  constructor: ->
    # 流程：
    # 第一个请求：验证用户是否登录

    # 登录验证书签服务
    #loading1 = show_loading_after @short_url_info.$el, '正在验证用户 …'
    @bg = chrome.extension.getBackgroundPage()
    @auth = new Auth(jQuery('.auth'), @)
    @auth.go =>
      #loading1.remove()

  bind_buttons: ->
    console.log 'bind_buttons'
    jQuery('.actions .fullpage').click ->
      console.log 'fullpage'
      takeScreenshot()
      #capturer = new Capturer()
      #capturer.capture_fullpage()
      #
      #@bg.screenshot.captureFullpage()
      #screenshot.sendMessage({msg: 'scroll_init'}, screenshot.onResponseVisibleSize)
      #
      #          case 'scroll_init': # Capture whole page.
      #                    sendResponse(merge(page.scrollInit(0, 0, document.body.scrollWidth, document.body.scrollHeight, 'captureFullpage'), {page_info:page_info}))

    jQuery('.actions .viewport').click ->
      chrome.tabs.captureVisibleTab null, format: "png", (data_url) ->
        console.log data_url
        $('.img').css 'background-image', "url(#{data_url})"

    jQuery('.actions .selection').click ->
      console.log 'selection'
    console.log 'bind_buttons end'

  show_info: ->
    console.log 'show info'
    @bind_buttons()
    #@add_message_listener()
    jQuery('.upload_info').fadeIn(ANIMATE_DURATION)
    console.log 'show info end'

  show_form: ->
    console.log 'show form'
    #@form = new Form jQuery('.form')
    #loading2 = show_loading_after @short_url_info.$el, '正在读取数据 …'
    #@form.load @url_info, =>
      #loading2.remove()
  
  #add_message_listener: ->
    #console.log 'add_message_listener'
    #chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
      #if (page.isSelectionAreaTurnOn)
        #page.removeSelectionArea()
      #selectedText = "#{(window.getSelection != undefined && window.getSelection()) || (document.getSelection != undefined && document.getSelection()) ||  document.selection.createRange().text}".replace(/(^\s+|\s+$)/g, "")
      #page_info = href: document.location.href, text: selectedText || document.title || ''

      #switch request.msg
        #when 'capture_viewport'
          #sendResponse(merge(page.getViewportSize(), {page_info: page_info}))
        #when 'show_selection_area'
          #page.showSelectionArea()
        #when 'scroll_init' #// Capture whole page.
          #sendResponse(merge(page.scrollInit(0, 0, document.body.scrollWidth, document.body.scrollHeight, 'captureFullpage'), {page_info:page_info}))
        #when 'scroll_next'
          #page.visibleWidth = request.visibleWidth
          #page.visibleHeight = request.visibleHeight
          #sendResponse(merge(page.scrollNext(), {page_info:page_info}))
        #when 'capture_selected'
          #cal_x = page.calculateSizeAfterZooming(page.endX - page.startX)
          #cal_y = page.calculateSizeAfterZooming(page.endY - page.startY)
          #sendResponse(merge(page.scrollInit(
                      #page.startX,
                      #page.startY,
                      #cal_x,
                      #cal_y,
                      #'captureSelected'), {page_info:page_info}))
#class Capturer
  #constructor: () ->
    #@_init()

  #_init: () ->
    #@canvas = document.createElement("canvas")
    #@yPos = 0
    #@scrollHeight = 0
    #@scrollWidth = 0

  #fetchPageSize: (tabId) =>
    #chrome.tabs.sendMessage(tabId, {act: 'fetchPageSize'}, @onResponseVisibleSize)

  #scrollPage: (tabId, x, y) =>
    #chrome.tabs.sendMessage(tabId, {act: 'scrollPage', x: x, y: y}, @onScrollDone)

  #onScrollDone: (resMsg) ->
    #console.log('onScrollDone', resMsg)
    #delay 1000, ->
      #Capturer.captureVisibleBlock()

  #startCapture: ->
    ## scroll to top
    #@yPos = 0
    #@scrollPage(@tabId, 0, -1 * @scrollHeight)
    ## self.postImg()

  #onResponseVisibleSize: (pageSize) ->
    #Capturer.scrollWidth = pageSize.scrollWidth
    #Capturer.scrollHeight = pageSize.scrollHeight
    #Capturer.clientWidth = pageSize.clientWidth
    #Capturer.clientHeight = pageSize.clientHeight

    #Capturer.canvas.width = pageSize.scrollWidth
    #Capturer.canvas.height = pageSize.scrollHeight

    #Capturer.startCapture()

  #captureVisibleBlock: (w, h) ->
    #self = this
    #width = w || self.clientWidth
    #height = h || self.clientHeight

    #chrome.tabs.captureVisibleTab null, (img) ->
      #blockImg = new Image()
      #canvas = self.canvas

      #if Capturer.yPos + Capturer.clientHeight >= Capturer.scrollHeight
        #blockImg.onload = ->
          #ctx = canvas.getContext("2d")
          #y = Capturer.clientHeight - Capturer.scrollHeight % Capturer.clientHeight
          #ctx.drawImage(blockImg, 0, 0, width, height, 0, self.yPos - y, width, height)
          #Capturer.postImg()
      #else
        #blockImg.onload = ->
          #ctx = canvas.getContext("2d")
          #ctx.drawImage(blockImg, 0, 0, width, height, 0, Capturer.yPos, width, height)
          #Capturer.yPos += Capturer.clientHeight
          #self.scrollPage(self.tabId, 0, Capturer.clientHeight)
      #blockImg.src = img

  #scrollToNextBlock: ->

  #postImg: () ->
    #canvas = Capturer.canvas
    #screenshotUrl = canvas.toDataURL()
    #viewTabUrl = chrome.extension.getURL('screenshot.html?id=' + id++)
    #chrome.tabs.create {url: viewTabUrl}, (tab) ->
      #targetId = tab.id

      #addSnapshotImageToTab = (tabId, changedProps) ->
        ## We are waiting for the tab we opened to finish loading.
        ## Check that the the tab's id matches the tab we opened,
        ## and that the tab is done loading.
        #if (tabId != targetId || changedProps.status != "complete")
            #return

        ## Passing the above test means this is the event we were waiting for.
        ## There is nothing we need to do for future onUpdated events, so we
        ## use removeListner to stop geting called when onUpdated events fire.
        #chrome.tabs.onUpdated.removeListener(addSnapshotImageToTab)

        ## Look through all views to find the window which will display
        ## the screenshot.  The url of the tab which will display the
        ## screenshot includes a query parameter with a unique id, which
        ## ensures that exactly one view will have the matching URL.
        #views = chrome.extension.getViews()
        #i = 0
        #while i < views.length
          #view = views[i]
          #if view.location.href == viewTabUrl
            #view.setScreenshotUrl(screenshotUrl)
            #break
      #chrome.tabs.onUpdated.addListener(addSnapshotImageToTab)

  #capture_fullpage: () ->
    #tabId = chrome.tabs.getSelected (tab) ->
      #@tabWin = window
      #@tabId = tab.id
      #console.log @fetchPageSize
      #@fetchPageSize(tab.id)


jQuery ->
  popup = new Popup
  
chrome.runtime.onMessage.addListener (request, sender) ->
  # receive 'fullpage' message from 'capturer.js'
  console.log msg
  if request.msg == 'fullpage'
    $('.img').css 'background-image', "url(#{msg.url})"
