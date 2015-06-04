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
        jQuery('.user-info').fadeIn(ANIMATE_DURATION)

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
    jQuery('.actions .fullpage').click ->
      takeScreenshot()

    jQuery('.actions .viewport').click ->
      chrome.tabs.captureVisibleTab null, format: "png", (data_url) ->
        window.upload_url = data_url
        chrome.storage.local.set {'src': data_url}, ->
          window.open(window.extension_base_url + "edit.html", "_blank")

    jQuery('.actions .selection').click ->
      chrome.tabs.getSelected (tab) =>
        # 直接在其他位置处理了
        chrome.tabs.sendMessage tab.id, {task: 'selection'}, @selection_callback
        window.close()

  selection_callback: (pageSize) ->
    # 选取截图，不在这个回调中处理
    #console.log 'selection_callback'

  show_actions: ->
    @bind_buttons()
    jQuery('.upload_info').fadeIn(ANIMATE_DURATION)

jQuery ->
  popup = new Popup

  window.extension_base_url = chrome.extension.getURL("")
