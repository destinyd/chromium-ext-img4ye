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
    #@$image.css 'background-image', "url(#{@src})"
    @$image.attr 'src', @src

  bind: ->
    that = this
    jQuery('button.upload').click ->
      window.up.add_file_by_base64(that.src)

class ExtFileProgress
  constructor: (@file, @uploader)->
    @obj_button = jQuery('button.upload')

  update: ->
    @obj_button.attr('disabled', true)
    @obj_button.text("上传中 #{@file.percent}%")

  success: (info)->
    window.info = info
    url = "#{HOST}/f/#{info.id}"
    jQuery('body.collect-4ye .success').html("上传成功<br /><a href='#{url}' target='_blank'>#{url}</a>").show()

  @alldone: ->
    console.log 'alldone'
    obj_button = jQuery('button.upload')
    obj_button.text('上传')
    obj_button.attr('disabled', false)

  error: ->
    console.log '上传失败'
    jQuery('body.collect-4ye .success').html("上传失败").show()

jQuery ->
  options = {
    browse_button: jQuery('.hidden'),
    auto_start: true,
    paste_upload: false,
    file_progress_callback: ExtFileProgress
  }
  window.up = new Img4yeUploader(options)

  image_edit = new ImageEdit()
