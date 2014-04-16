module.exports = ->
  http = require('http')
  Layer = require('./layer')

  handler = (request, response, next)->
    findParentNext = (parent)->
      pIndex = parent.stack.indexOf(handler.wrap)
      pNext = parent.stack[pIndex + 1]

    responseWith = (code)->
      response.statusCode = code
      response.end()

    if handler.stack.length == 0
      if parent = handler.parent
        findParentNext(parent).handle(request, response)
      else
        responseWith(404)
        return

    index = -1

    findNearNormalLayer = (index)->
      for s in handler.stack[index..-1]
        return s if s.handle.length < 4 and s.match(request.url)

    findNearErrorLayer = (index)->
      for s in handler.stack[index..-1]
        return s if s.handle.length == 4 and s.match(request.url)

    errorNext = (err)->
      if nextLayer = findNearErrorLayer(index)
        nextLayer.handle(err, request, response, next)
      else
        if parent = handler.parent
          findParentNext(parent).handle(err, request, response)
        else
          responseWith(500)

    normalNext = ()->
      if nextLayer = findNearNormalLayer(index)
        try
          nextLayer.handle(request, response, next)
        catch e
          errorNext(e)
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
      middleware.wrap = layer
    handler.stack.push layer

  handler
