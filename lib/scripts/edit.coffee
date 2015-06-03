class ImageEdit
  constructor: () ->
    @$image = jQuery('.collect-4ye .image')
    @src = null
    @sync_get_src()
    @bind()

  sync_get_src: ->
    console.log "sync_get_src"
    that = this
    chrome.storage.local.get "src", (obj) ->
      console.log "storage local get"
      console.log obj
      that.src = obj.src
      that.show_image()

  show_image: ->
    console.log "show_image"
    console.log "url(#{@src})"
    @$image.css 'background-image', "url(#{@src})"

  bind: ->
    that = this
    jQuery('button.upload').click ->
      window.up.add_file_by_base64(that.src)

class ExtFileProgress
  constructor: (@$files_ele, @file)->
    console.log 'ExtFileProgress'
    console.log @$files_ele
    console.log @file
    @obj_button = jQuery('button.upload')
    #@$files_ele = jQuery(@$files_ele)
    #@obj_info = @$files_ele.find('.info')

  refresh_progress: ->
    console.log("refresh_progress #{@file.percent}%", )
    @obj_button.text("上传中 #{@file.percent}%")

  upload_success: (info)->
    console.log("uploaded")
    window.info = info
    jQuery('body.collect-4ye .success').html("上传成功<br /><a href='#{info.url}' target='_blank'>#{info.url}</a>").show()
    #@$files_ele.html("上传成功<br /><a href='#{info.url}' target='_blank'>#{info.url}</a>")

  upload_end: ->
    @obj_button.text('上传')
    @obj_button.attr('disabled', false)
    console.log("upload_end")
    #@$files_ele.fadeOut ANIMATE_DURATION

  upload_error: ->
    console.log("upload_error")
    @obj_info.text("上传失败")

  start_upload: ->
    #@$files_ele.show()
    @obj_button.text('上传中...')
    @obj_button.attr('disabled', true)
    console.log("start_upload")

jQuery ->
  options = {
    qiniu_domain:    "http://7xie1v.com1.z0.glb.clouddn.com/", 
    qiniu_basepath:  "i",
    browse_button: jQuery('.hidden'),
    uptoken_url:     HOST + '/file_entities/uptoken',
    auto_start: true,
    paste_upload: false,
    file_list_area: jQuery('body.collect-4ye .loading'),
    file_progress_callback: ExtFileProgress
  }
  window.up = new Img4yeUploader(options)

  image_edit = new ImageEdit()
