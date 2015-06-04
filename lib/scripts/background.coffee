chrome.runtime.onMessage.addListener (request, sender, respond) ->
  if request.task == 'fullpage'
    $('.img').css 'background-image', "url(#{msg.url})"
  else if request.task == "capture"
    chrome.tabs.captureVisibleTab null, {format: "png"}, respond
  else if request.task == "get_extension_base_url"
    respond({url: chrome.extension.getURL("")})
  else
  true
