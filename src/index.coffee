module.exports = ->
  http = require('http')
  Layer = require('./layer')

  handler = (request, response)->
    findParentNext = (parent)->
      pIndex = parent.stack.indexOf(handler.wrap)
      pNext = parent.stack[pIndex + 1]

    responseWith = (code)->
      response.statusCode = code
      response.end()

    index = -1

    findNearNormalLayer = (index)->
      for l in handler.stack[index..-1]
        return l if l.handle.length < 4 and l.match(request.url)

    findNearErrorLayer = (index)->
      for l in handler.stack[index..-1]
        return l if l.handle.length == 4 and l.match(request.url)

    normalEnd = ->
      if (parent = handler.parent) && (pNext = findParentNext(parent))
        pNext.handle(request, response)
      else
        responseWith(404)

    errorEnd = (err)->
      if (parent = handler.parent) && (pNext = findParentNext(parent))
        pNext.handle(err, request, response)
      else
        responseWith(500)

    normalNext = ->
      if nextLayer = findNearNormalLayer(index)
        try
          nextLayer.handle(request, response, next)
        catch e
          errorNext(e)
      else
        normalEnd()

    errorNext = (err)->
      if nextLayer = findNearErrorLayer(index)
        nextLayer.handle(err, request, response, next)
      else
        errorEnd(err)

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
