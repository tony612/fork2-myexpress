express = require("../")
request = require("supertest")
http = require("http")
Layer = require("../src/layer")

describe "layer", ->
  beforeEach ->
    @middleware = ->
    @layer = new Layer("/foo", @middleware)

  describe '#constructor', ->
    it "sets layer.handle to be the middleware", ->
      expect(@layer.handle).to.equal(@middleware)
      expect(@layer.path).to.eql('/foo')

  describe '#match', ->
    it "returns undefined if path doesn't match", ->
      expect(@layer.match('/bar')).to.be.undefined

    it "returns matched path if layer matches the request path exactly", ->
      expect(@layer.match('/foo')).to.eql({path: '/foo'})

    it "returns matched prefix if the layer matches the prefix of the request path", ->
      expect(@layer.match('/foo/bar')).to.eql({path: '/foo'})

    describe 'regex', ->
      beforeEach ->
        @layer = new Layer('/foo/:a/:b', @middleware)

      it "returns undefined for unmatched path", ->
        expect(@layer.match('/foo')).to.be.undefined

      it "returns undefined if there isn't enough parameters", ->
        expect(@layer.match('/foo/apple')).to.be.undefined

      it "returns match data for exact match", ->
        result =
          path: '/foo/apple/xiaomi',
          params:
            a: 'apple',
            b: 'xiaomi'

        expect(@layer.match('/foo/apple/xiaomi')).to.eql(result)

      it "returns match data for prefix match", ->
        result =
          path: '/foo/apple/xiaomi',
          params:
            a: 'apple',
            b: 'xiaomi'

        expect(@layer.match('/foo/apple/xiaomi/htc')).to.eql(result)

      it "should decode uri encoding", ->
        result =
          path: '/foo/apple/xiao mi',
          params:
            a: 'apple',
            b: 'xiao mi'

        expect(@layer.match('/foo/apple/xiao%20mi')).to.eql(result)

      it "should strip trailing slash", ->
        layer = new Layer('/')
        expect(layer.match("/foo")).to.not.be.undefined;
        expect(layer.match("/")).to.not.be.undefined;

        layer = new Layer("/foo/")
        expect(layer.match("/foo")).to.not.be.undefined;
        expect(layer.match("/foo/")).to.not.be.undefined;
