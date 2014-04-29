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

  app = (request, response)->
    originUrl = request.url

    request.url = originUrl.replace app.parentUrl, '' if app.parentUrl

    findParentNext = (parent)->
      pIndex = parent.stack.indexOf(app.wrap)
      pNext = parent.stack[pIndex + 1]

    endResponse = (err)->
      code = if err then 500 else 404
      response.statusCode = code
      response.end()

    index = -1

    setReqUrlBack = ->
      request.url = originUrl

    findNearLayer = (index, err)->
      isMatch = (length)-> if !!err then length == 4 else length < 4
      for l in app.stack[index..-1]
        if isMatch(l.handle.length) && (match = l.match(request.url))
          request.params = mergeObjs(request.params, match.params)
          return l

    paramsWithErr = (err)->
      args = Array.prototype.slice.call(arguments, 0)
      args.shift() unless err
      args

    end = (err)->
      parent = app.parent
      pNext = findParentNext(parent) if parent
      return endResponse(err)  unless pNext

      setReqUrlBack()

      pNext.handle.apply(null, paramsWithErr(err, request, response))

    next = (err)->
      index += 1

      nextLayer = findNearLayer(index, err)
      return end(err) unless nextLayer

      try
        nextLayer.handle.apply(null, paramsWithErr(err, request, response, next))
      catch e
        next(e)

    next()

  app.listen = (port, callback)->
    http.createServer(app).listen(port, callback)

  app.handle = app
  app.stack = []

  app.use = (path, middleware)->
    [path, middleware] = ['/', path] if !middleware

    if typeof middleware.handle == 'function'
      middleware.parentUrl = path

    layer = new Layer(path, middleware)
    if middleware.stack
      middleware.parent = app
      middleware.wrap = layer
    app.stack.push layer

  app
