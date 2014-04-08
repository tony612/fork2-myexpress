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
    app.listen(7000)
    it "listens to a port", (done)->
      request("http://localhost:7000").get("/foo").expect(404).end(done)
