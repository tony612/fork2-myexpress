// Generated by CoffeeScript 1.7.1
(function() {
  var Layer, p2re;

  p2re = require('path-to-regexp');

  Layer = (function() {
    function Layer(path, handle) {
      this.path = path;
      this.handle = handle;
      this.path = this.path.replace(/\/$/, '');
      this.pathNames = [];
      this.re = p2re(this.path, this.pathNames, {
        end: false
      });
    }

    Layer.prototype.match = function(path) {
      var execed, i, params, pathName, result, _i, _len, _ref;
      path = decodeURIComponent(path);
      if (execed = this.re.exec(path)) {
        result = {
          path: execed[0]
        };
        params = {};
        _ref = this.pathNames;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          pathName = _ref[i];
          params[pathName.name] = execed[i + 1];
        }
        if (Object.keys(params).length > 0) {
          result.params = params;
        }
        return result;
      }
    };

    return Layer;

  })();

  module.exports = Layer;

}).call(this);
