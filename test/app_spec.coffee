express = require("../")
request = require("supertest")
http = require("http")

describe "app", ->
  app = express()

  describe "Empty app", ->
    it "responds to / with 404", (done)->
      server = http.createServer(app)
      request(server).get('/').expect(404).end(done)

  describe "#listen", ->
    before (done)->
      @server = app.listen(7000, done)

    it "returns an http.Server", ->
      expect(@server).to.be.instanceof(http.Server)

    it "listens to a port", (done)->
      request("http://localhost:7000").get("/").expect(404).end(done)


  describe '#use', ->
    beforeEach ->
      @app = new express()
      @middleware = ->

    it "creates a root path layer", ->
      @app.use @middleware
      layer = @app.stack[0]
      expect(layer.handle).to.equal(@middleware)
      expect(layer.path).to.eql('/')

    it "creates a specified path layer", ->
      @app.use '/foo', @middleware
      layer = @app.stack[0]
      expect(layer.handle).to.equal(@middleware)
      expect(layer.path).to.eql('/foo')

  #   it "adds middleware to stack", ->
  #     m1 = ->
  #     m2 = ->
  #     app.use(m1);
  #     app.use(m2);
  #     expect(app.stack[0]).to.equal(m1)
  #     expect(app.stack[1]).to.equal(m2)

  describe "calling middleware stack", ->
    beforeEach ->
      @app = new express()
      @server = http.createServer(@app)

    it "can call a single middleware", (done)->
      m1 = (req, res, next)->
        res.end "hello from m1"
      @app.use m1
      request(@server).get('/').expect("hello from m1").end(done)

    it "can call next to go to next middleware", (done)->
      m1 = (req,res,next)->
        next()
      m2 = (req,res,next)->
        res.end("hello from m2")
      @app.use(m1);
      @app.use(m2);

      request(@server).get('/').expect("hello from m2").end(done)

    it "returns 404 at the end of the chain", (done)->
      m1 = (req,res,next)->
        next()
      m2 = (req,res,next)->
        next()
      @app.use(m1);
      @app.use(m2);

      request(@server).get('/').expect(404).end(done)

    it "returns 404 if no middleware is added", (done)->
      @app.stack = []

      request(@server).get('/').expect(404).end(done)

  describe "error handling", ->
    beforeEach ->
      @app = new express()
      @server = http.createServer(@app)

    it "should return 500 for unhandled error", (done)->
      m1 = (req,res,next)->
        next(new Error("boom!"))
      @app.use(m1)

      request(@server).get('/').expect(500).end(done)

    it "should return 500 for uncaught error", (done)->
      m1 = (req,res,next)->
        throw new Error("boom!")
      @app.use(m1)

      request(@server).get('/').expect(500).end(done)

    it "should skip error handlers when next is called without an error", (done)->
      m1 = (req, res, next) ->
        next()

      e1 = (err, req, res, next) ->
        # timeout

      m2 = (req, res, next) ->
        res.end "m2"

      @app.use m1
      @app.use e1 # should skip this. will timeout if called.
      @app.use m2

      request(@server).get('/').expect(200).end(done)

    it "should skip normal middlewares if next is called with an error", (done)->
      m1 = (req, res, next) ->
        next new Error("boom!")
        return

      m2 = (req, res, next) ->
        # timeout

      e1 = (err, req, res, next) ->
        res.end "e1"

      @app.use m1
      @app.use m2 # should skip this. will timeout if called.
      @app.use e1

      request(@server).get('/').expect(200).end(done)

  describe "implement app embedding as middleware", ->
    it "should pass unhandled request to parent", (done)->
      m2 = (req, res, next) ->
        res.end "m2"
      app = new express()
      subApp = new express()
      app.use subApp
      app.use m2

      server = http.createServer(app)

      request(server).get('/').expect(200, "m2").end(done)

    it "should return 404 when there's no layer next", (done)->
      m2 = (req, res, next) ->
        res.end "m2"
        return
      app = new express()
      subApp = new express()
      app.use subApp

      server = http.createServer(app)

      request(server).get('/').expect(404).end(done)

    it "should pass unhandled error to parent", (done)->
      m1 = (req, res, next) ->
        next "m1 error"
        return
      e1 = (err, req, res, next) ->
        res.end err
        return
      app = new express()
      subApp = new express()
      subApp.use m1
      app.use subApp
      app.use e1

      server = http.createServer(app)

      request(server).get('/').expect(200, "m1 error").end(done)

  describe "use path matched layers", ->
    beforeEach ->
      @app = new express()
      @app.use "/foo", (req, res, next) ->
        res.end "foo"

      @app.use "/", (req, res) ->
        res.end "root"

      @server = http.createServer(@app)

    it "for GET /", (done)->
      request(@server).get('/').expect(200, 'root').end(done)

    it "for GET /foo", (done)->
      request(@server).get('/foo').expect(200, 'foo').end(done)

    it "for GET /foo/bar", (done)->
      request(@server).get('/foo/bar').expect(200, 'foo').end(done)

  describe "use path matched error layers", ->
    beforeEach ->
      @app = new express()
      @app.use "/foo", (req, res, next) ->
        throw "boom!"

      @app.use "/foo/a", (err, req, res, next) ->
        res.end "error handled /foo/a"

      @app.use "/foo/b", (err, req, res, next) ->
        res.end "error handled /foo/b"

      @server = http.createServer(@app)

    it "for unmatched error", (done)->
      request(@server).get('/foo').expect(500).end(done)

    it "GET /foo/a", (done)->
      request(@server).get('/foo/a').expect(200, "error handled /foo/a").end(done)

    it "GET /foo/b", (done)->
      request(@server).get('/foo/b').expect(200, "error handled /foo/b").end(done)
