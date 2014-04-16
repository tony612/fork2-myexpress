express = require("../")
request = require("supertest")
http = require("http")
Layer = require("../src/layer")

describe "app", ->
  beforeEach ->
    @middleware = ->
    @layer = new Layer("/foo", @middleware)

  describe '#constructor', ->
    it "sets layer.handle to be the middleware", ->
      expect(@layer.handle).to.equal(@middleware)
      expect(@layer.path).to.equal('/foo')

  describe '#match', ->
    it "returns undefined if path doesn't match", ->
      expect(@layer.match('/bar')).to.be.undefined

    it "returns matched path if layer matches the request path exactly", ->
      expect(@layer.match('/foo')).to.eql({path: '/foo'})

    it "returns matched prefix if the layer matches the prefix of the request path", ->
      expect(@layer.match('/foo/bar')).to.eql({path: '/foo'})
