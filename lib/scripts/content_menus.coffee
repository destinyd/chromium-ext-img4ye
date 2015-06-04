class ContentMenu
  constructor: () ->
    @_init()
    @create_content_menus()

  _init: ->
    @upload_url = HOST + "/api/file_entities/input_from_remote_url_to_quene"
    @upload_state_url = HOST + "/api/file_entities/get_from_remote_url_status"

  create_content_menus: ->
    # 只采集图片
    id = chrome.contextMenus.create {"title": "采集图片", "contexts":["image"], "onclick": @onclick}

  convert_image_to_base64: (url, @callback, output_farmat) ->
    @img = new Image()
    @img.crossOrigin = 'Anonymous'
    @img.onload = =>
      canvas = document.createElement('canvas')
      ctx = canvas.getContext('2d')
      canvas.height = @img.height
      canvas.width = @img.width
      ctx.drawImage(@img,0,0)
      dataURL = canvas.toDataURL(output_farmat || 'image/png')
      @callback(dataURL)
      canvas = null; 
    @img.src = url

  onclick: (info, tab)=>
    @convert_image_to_base64 info.srcUrl, (base64_image)->
      chrome.storage.local.set {'src': base64_image}, ->
        if chrome.runtime.lastError
          alert("图片太大，暂不支持采集")
        else
          window.open(window.extension_base_url + "edit.html", "_blank")

jQuery ->
  window.extension_base_url = chrome.extension.getURL("")

  new ContentMenu()
