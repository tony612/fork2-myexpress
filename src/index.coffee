module.exports = ->
  (request, response)->
    response.statusCode = 404
    response.end()
