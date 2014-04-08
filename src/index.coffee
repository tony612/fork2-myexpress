module.exports = ->
  http = require('http')

  handler = (request, response)->
    response.statusCode = 404
    response.end()

  handler.listen = (port, callback)->
    http.createServer(handler).listen(port, callback)

  handler
