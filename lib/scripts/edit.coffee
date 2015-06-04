class ImageEdit
  constructor: () ->
    @$image = jQuery('.collect-4ye .image')
    @src = null
    @sync_get_src()
    @bind()

  sync_get_src: ->
    that = this
    chrome.storage.local.get "src", (obj) ->
      that.src = obj.src
      that.show_image()

  show_image: ->
    @$image.css 'background-image', "url(#{@src})"

  bind: ->
    that = this
    jQuery('button.upload').click ->
      window.up.add_file_by_base64(that.src)

class ExtFileProgress
  constructor: (@$files_ele, @file)->
    @obj_button = jQuery('button.upload')

  refresh_progress: ->
    @obj_button.text("上传中 #{@file.percent}%")

  upload_success: (info)->
    window.info = info
    jQuery('body.collect-4ye .success').html("上传成功<br /><a href='#{info.url}' target='_blank'>#{info.url}</a>").show()

  upload_end: ->
    @obj_button.text('上传')
    @obj_button.attr('disabled', false)

  upload_error: ->
    console.log '上传失败'
    jQuery('body.collect-4ye .success').html("上传失败").show()

  start_upload: ->
    @obj_button.text('上传中...')
    @obj_button.attr('disabled', true)

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
