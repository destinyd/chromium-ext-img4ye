jQuery.randstr = (length)->
  if null == length || "undefined" == typeof length
    length = 8
  base = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  size = base.length
  re = '' 
  re += base[Math.floor(Math.random()*(size-10))]
  for num in [1..length-1]
    re += base[Math.floor(Math.random()*size)]
  re

jQuery.data_uri_to_blob = (data_uri, type)->
  # convert base64 to raw binary data held in a string
  byteString = atob(data_uri.split(',')[1])

  # separate out the mime component
  mimeString = data_uri.split(',')[0].split(':')[1].split(';')[0]

  # write the bytes of the string to an ArrayBuffer
  ab = new ArrayBuffer(byteString.length)
  ia = new Uint8Array(ab)
  ia[i] = byteString.charCodeAt(i) for tmp, i in byteString

  # write the ArrayBuffer to a blob, and you're done
  new Blob([ab], { type: type })
