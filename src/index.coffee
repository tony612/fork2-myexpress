module.exports = ->
  http = require('http')

  handler = (request, response)->
    index = -1
    next = ->
      index += 1
      if nextWare = handler.stack[index]
        nextWare(request, response, next)
      else
        response.statusCode = 404

    next()

    response.end()

  handler.listen = (port, callback)->
    http.createServer(handler).listen(port, callback)

  handler.stack = []

  handler.use = (middleware)->
    handler.stack.push middleware

  handler
