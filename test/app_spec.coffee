express = require("../")
request = require("supertest")
http = require("http")

describe "app", ->
  app = express()

  describe "Empty app", ->
    it "responds to /foo with 404", (done)->
      server = http.createServer(app)
      request(server).get('/foo').expect(404).end(done)

  describe "#listen", ->
    before (done)->
      @server = app.listen(7000, done)

    it "returns an http.Server", ->
      expect(@server).to.be.instanceof(http.Server)

    it "listens to a port", (done)->
      request("http://localhost:7000").get("/foo").expect(404).end(done)

  describe "#use", ->
    it "adds middleware to stack", ->
      m1 = ->
      m2 = ->
      app.use(m1);
      app.use(m2);
      expect(app.stack[0]).to.equal(m1)
      expect(app.stack[1]).to.equal(m2)

  describe "calling middleware stack", ->
    beforeEach ->
      @app = new express()
      @server = http.createServer(@app)

    it "can call a single middleware", (done)->
      m1 = (req, res, next)->
        res.end "hello from m1"
      @app.use m1
      request(@server).get('/foo').expect("hello from m1").end(done)

    it "can call next to go to next middleware", (done)->
      m1 = (req,res,next)->
        next()
      m2 = (req,res,next)->
        res.end("hello from m2")
      @app.use(m1);
      @app.use(m2);

      request(@server).get('/foo').expect("hello from m2").end(done)

    it "returns 404 at the end of the chain", (done)->
      m1 = (req,res,next)->
        next()
      m2 = (req,res,next)->
        next()
      @app.use(m1);
      @app.use(m2);

      request(@server).get('/foo').expect(404).end(done)

    it "returns 404 if no middleware is added", (done)->
      @app.stack = []

      request(@server).get('/foo').expect(404).end(done)
