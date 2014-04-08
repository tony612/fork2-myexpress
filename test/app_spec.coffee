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
