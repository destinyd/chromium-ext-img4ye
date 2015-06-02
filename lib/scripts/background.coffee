#chrome.browserAction.onClicked.addListener (tab) ->
  #chrome.tabs.sendMessage tab.id, {task: "selection"}

chrome.runtime.onMessage.addListener (request, sender, respond) ->
  # receive 'fullpage' message from 'capturer.js'
  console.log 'runtime on message'
  console.log request
  if request.task == 'fullpage'
    $('.img').css 'background-image', "url(#{msg.url})"
  else if request.task == "capture"
    console.log 'task capture'
    chrome.tabs.captureVisibleTab null, {format: "png"}, respond
  else
    console.log 'nothing'
  true
