express = require("../")
request = require("supertest")
http = require("http")

describe "app", ->
  app = express()

  describe "Empty app", ->
    it "responds to /foo with 404", (done)->
      server = http.createServer(app)
      request(server).get('/foo').expect(404).end(done)
