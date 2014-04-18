p2re = require('path-to-regexp')

class Layer
  constructor: (@path, @handle)->
    @path = @path.replace /\/$/, ''
    @pathNames = []
    @re = p2re @path, @pathNames, {end: false}

  match: (path)->
    path = decodeURIComponent(path)
    if execed = @re.exec(path)
      result = {path: execed[0]}
      params = {}
      params[pathName.name] = execed[i + 1] for pathName, i in @pathNames
      result.params = params if Object.keys(params).length > 0
      result

module.exports = Layer
