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
    console.log "item:" + id

  convert_image_to_base64: (url, @callback, output_farmat) ->
    console.log 'convert_image_to_base64'
    @img = new Image()
    @img.crossOrigin = 'Anonymous'
    @img.onload = =>
      canvas = document.createElement('canvas')
      ctx = canvas.getContext('2d')
      console.log @img
      canvas.height = @img.height
      canvas.width = @img.width
      ctx.drawImage(@img,0,0)
      dataURL = canvas.toDataURL(output_farmat || 'image/png')
      @callback(dataURL)
      canvas = null; 
    @img.src = url

  onclick: (info, tab)=>
    console.log 'onclick'
    console.log info
    console.log info.srcUrl
    console.log tab
    #@upload(info.srcUrl)
    @convert_image_to_base64 info.srcUrl, (base64_image)->
      console.log 'convert_image_to_base64 callback'
      console.log base64_image
      chrome.storage.local.set {'src': base64_image}, ->
        if chrome.runtime.lastError
          alert("图片太大，暂不支持采集")
        else
          console.log 'storage'
          window.open(window.extension_base_url + "edit.html", "_blank")

  #upload: (url) ->
    #that = this
    #jQuery.ajax
      #type: "POST",
      #url: @upload_url,
      #data: {url: url},
      #success: (res) ->
        #console.log 'success join upload process'
        #that.timestamp = Date.parse(new Date())
        #that.token = res.token
        #that.refresh_upload_state(res.token)
        ##avatar = res.avatar
        ##naQuery('.user-info .name').text name
         ##jQuery('.user-info').fadeIn(ANIMATE_DURATION)
        ##jQuery('.user-info').fadeIn(ANIMATE_DURATION)

         ##绑定按钮操作
        ##@pme = res.name
        ##jQuery('.user-info .avatar').css 'background-image', "url(#{avatar})"
        ##jQuery('.user-info .name').text name
  #refresh_upload_state: (@token) ->
    #that = this
    #token = @token
    #jQuery.ajax
      #type: "GET",
      #url: @upload_state_url + "?token=" + @token,
      #success: (res) ->
        #if res.status == 'processing'
          #that.refresh_upload_state(token)
        #else
          #timestamp = Date.parse(new Date())
          #console.log "上传成功，共花费 #{timestamp - that.timestamp} ms。网址："
          #console.log "#{res.data.url}"


jQuery ->
  window.extension_base_url = chrome.extension.getURL("")

  new ContentMenu()
