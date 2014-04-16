module.exports = ->
  http = require('http')
  domain = require('domain')
  Layer = require('./layer')

  handler = (request, response, next)->
    findParentNext = ->
      pIndex = parent.stack.indexOf(handler)
      pNext = parent.stack[pIndex + 1]

    responseWith = (code)->
      response.statusCode = code
      response.end()

    if handler.stack.length == 0
      if parent = handler.parent
        findParentNext()(request, response)
      else
        responseWith(404)
        return

    index = -1

    findNearNormalLayer = (index)->
      for s in handler.stack[index..-1]
        return s if s.length < 4

    findNearErrorLayer = (index)->
      for s in handler.stack[index..-1]
        return s if s.length == 4

    errorNext = (err)->
      if nextLayer = findNearErrorLayer(index)
        nextLayer(err, request, response, next)
      else
        if parent = handler.parent
          findParentNext()(err, request, response)
        else
          responseWith(500)

    normalNext = ()->
      if nextLayer = findNearNormalLayer(index)
        try
          nextLayer(request, response, next)
        catch e
          responseWith(500)
      else
        responseWith(404)

    next = (err)->
      index += 1
      if err
        errorNext(err)
      else
        normalNext()

    next()

  handler.listen = (port, callback)->
    http.createServer(handler).listen(port, callback)

  handler.stack = []

  handler.use = (path, middleware)->
    [path, middleware] = ['/', path] if !middleware
    layer = new Layer(path, middleware)
    if middleware.stack
      middleware.parent = handler
    handler.stack.push layer

  handler
