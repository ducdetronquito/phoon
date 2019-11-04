import asynchttpserver
import ../express/express
import ../express/response
import ../express/routing/router
import unittest
import utils


suite "Endpoints":
    
    test "GET endpoint":
        let request = GetRequest("https://yumad.bro/")
        var app = App.new()
        app.get("/",
            proc (request: Request): Response =
                return Ok("I am a boring home page")
        )
        app.compile_routes()
        let response = app.dispatch(request)
        check(response.status_code == Http200)
        check(response.body == "I am a boring home page")

    test "POST endpoint":
        let request = PostRequest("https://yumad.bro/")
        var app = App.new()
        app.post("/",
            proc (request: Request): Response =
                return Created("I super JSON payloard")
        )
        app.compile_routes()
        let response = app.dispatch(request)
        check(response.status_code == Http201)
        check(response.body == "I super JSON payloard")

    test "Can GET a endpoint already defined to handle POST requests":
        let request = GetRequest("https://yumad.bro/memes")
        var app = App.new()
        app.post("/memes",
            proc (request: Request): Response =
                return Created("Create a meme")
        )
        app.get("/memes",
            proc (request: Request): Response =
                return Ok("Retrieve all the good memes")
        )
        app.compile_routes()
        let response = app.dispatch(request)
        check(response.status_code == Http200)

    test "Can POST a endpoint already defined to handle GET requests":
      let request = PostRequest("https://yumad.bro/memes")
      var app = App.new()
      app.get("/memes",
          proc (request: Request): Response =
              return Ok("Retrieve all the good memes")
      )
      app.post("/memes",
          proc (request: Request): Response =
              return Created("Create a meme")
      )
      app.compile_routes()
      let response = app.dispatch(request)
      check(response.status_code == Http201)

    test "Not found endpoint returns a 404 status code.":
        let request = GetRequest("https://yumad.bro/an-undefined-url")
        var app = App.new()
        app.get("/",
            proc (request: Request): Response =
                return Ok("I am a boring home page")
        )
        app.compile_routes()
        let response = app.dispatch(request)
        check(response.status_code == Http404)

    test "Wrong HTTP method on a defined endpoint returns a 405 status code.":
      let request = GetRequest("https://yumad.bro/")
      var app = App.new()
      app.post("/",
          proc (request: Request): Response =
              return Ok("I am a boring home page")
      )
      app.compile_routes()
      let response = app.dispatch(request)
      check(response.status_code == Http405)

      test "Can define a nested router":
        let request = GetRequest("https://yumad.bro/api/v1/users")
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (request: Request): Response =
                return Ok("Some nice users")
        )

        app.mount("/api/v1", router)

        app.compile_routes()
        let response = app.dispatch(request)
        check(response.status_code == Http200)
        check(response.body == "Some nice users")
