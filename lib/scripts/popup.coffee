delay = (ms, func) -> setTimeout func, ms
class Auth
  constructor: (@$el, @popup)->
    @$signin_btn = @$el.find('.signin')

  go: (func)->
    jQuery.ajax "#{HOST}/api/auth_check"
      .done (res)=>
        # 验证通过，显示用户信息
        #avatar = res.avatar
        name = res.name
        #jQuery('.user-info .avatar').css 'background-image', "url(#{avatar})"
        jQuery('.user-info .name').text name
        #jQuery('.user-info').fadeIn(ANIMATE_DURATION)
        jQuery('.user-info').show()

        # 绑定按钮操作
        @popup.show_actions()

      .fail (err)=>
        # 验证未通过，显示登录按钮
        # @$el.fadeIn(ANIMATE_DURATION)
        console.log '未登录'
        @$el.show()

      .always =>
        func()

class Popup
  constructor: ->
    @bg = chrome.extension.getBackgroundPage()
    @auth = new Auth(jQuery('.auth'), @)
    @auth.go =>
      #loading1.remove()

  bind_buttons: ->
    that = this
    jQuery('.actions .fullpage').click ->
      chrome.tabs.getSelected (tab) =>
        # 直接在其他位置处理了
        chrome.tabs.sendMessage tab.id, {task: 'fullpage'}, @fullpage_callback
        window.close()
      #takeScreenshot()

    jQuery('.actions .viewport').click ->
      chrome.tabs.getSelected (tab) =>
        chrome.tabs.sendMessage tab.id, {task: 'before'}, @null_callback
        delay 200, -> 
          that.capture_viewport()

    jQuery('.actions .selection').click ->
      chrome.tabs.getSelected (tab) =>
        # 直接在其他位置处理了
        chrome.tabs.sendMessage tab.id, {task: 'selection'}, @selection_callback
        window.close()

  capture_viewport: (pageSize) ->
    #console.log 'capture_viewport'
    that = this

    chrome.tabs.captureVisibleTab null, format: "png", (data_url) ->
      that.send_after()
      window.upload_url = data_url
      chrome.storage.local.set {'src': data_url}, ->
        window.open(window.extension_base_url + "edit.html", "_blank")

  send_after: () ->
    chrome.tabs.getSelected (tab) =>
      chrome.tabs.sendMessage tab.id, {task: 'after'}, @null_callback

  fullpage_callback: (pageSize) ->
    #console.log 'fullpage_callback'

  selection_callback: (pageSize) ->
    # 选取截图，不在这个回调中处理
    #console.log 'selection_callback'
    
  null_callback: (pageSize) ->
    #console.log 'null_callback'

  show_actions: ->
    @bind_buttons()
    #jQuery('.upload_info').fadeIn(ANIMATE_DURATION)
    jQuery('.upload_info').show()

jQuery ->
  popup = new Popup

  window.extension_base_url = chrome.extension.getURL("")
