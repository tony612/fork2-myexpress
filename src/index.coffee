module.exports = ->
  http = require('http')
  domain = require('domain')

  handler = (request, response)->
    if handler.stack.length == 0
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
    handler.stack.push middleware

  handler
