module.exports = ->
  http = require('http')
  domain = require('domain')

  handler = (request, response, next)->
    if handler.stack.length == 0
      parent = handler.parent
      if parent
        pIndex = parent.stack.indexOf(handler)
        pNext = parent.stack[pIndex + 1]
        pNext(request, response)
      else
        response.statusCode = 404
        response.end()
        return

    index = -1

    findNearNormalStack = (index)->
      for s in handler.stack[index..-1]
        return s if s.length < 4

    findNearErrorStack = (index)->
      for s in handler.stack[index..-1]
        return s if s.length == 4

    responseWith = (code)->
      response.statusCode = code
      response.end()

    errorNext = (err)->
      if nextStack = findNearErrorStack(index)
        nextStack(err, request, response, next)
      else
        parent = handler.parent
        if parent
          pIndex = parent.stack.indexOf(handler)
          pNext = parent.stack[pIndex + 1]
          pNext(err, request, response)
        else
          responseWith(500)

    normalNext = ()->
      if nextStack = findNearNormalStack(index)
        try
          nextStack(request, response, next)
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

  handler.use = (middleware)->
    if middleware.stack
      middleware.parent = handler
    handler.stack.push middleware

  handler
