module.exports = ->
  http = require('http')
  Layer = require('./layer')

  mergeObjs = (obj1, obj2)->
    obj3 = {}
    obj1 ||= {}
    obj2 ||= {}
    obj3[k] = obj1[k] for k, v of obj1
    obj3[k] = obj2[k] for k, v of obj2
    obj3

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
        if l.handle.length < 4 && (match = l.match(request.url))
          request.params = mergeObjs(request.params, match.params)
          return l

    findNearErrorLayer = (index)->
      for l in handler.stack[index..-1]
        if l.handle.length == 4 && (match = l.match(request.url))
          request.params = mergeObjs(request.params, match.params)
          return l

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
