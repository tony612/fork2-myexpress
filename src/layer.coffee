class Layer
  constructor: (@path, @handle)->

  match: (path)->
    {path: @path} if path.indexOf(@path) >= 0


module.exports = Layer
