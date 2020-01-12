import phoon
import strutils
import unittest
import utils


suite "Endpoints":

    test "DELETE endpoint":
        var context = Context(request: Request(HttpMethod.HttpDelete, "https://yumad.bro/"))
        var app = App.new()
        app.delete("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a DELETE endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)
        check(response.body == "I am a DELETE endpoint")

    test "GET endpoint":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a GET endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)
        check(response.body == "I am a GET endpoint")

    test "HEAD endpoint":
        var context = Context(request: Request(HttpMethod.HttpHead, "https://yumad.bro/"))
        var app = App.new()
        app.head("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a HEAD endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)
        check(response.body == "I am a HEAD endpoint")

    test "OPTIONS endpoint":
        var context = Context(request: Request(HttpMethod.HttpOptions, "https://yumad.bro/"))
        var app = App.new()
        app.options("/",
            proc (context: Context) {.async.} =
                context.NoContent("I am an OPTIONS endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http204)
        check(response.body == "I am an OPTIONS endpoint")

    test "PATCH endpoint":
        var context = Context(request: Request(HttpMethod.HttpPatch, "https://yumad.bro/"))
        var app = App.new()
        app.patch("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a PATCH endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)
        check(response.body == "I am a PATCH endpoint")

    test "POST endpoint":
        var context = Context(request: PostRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) {.async.} =
                context.Created("I super JSON payloard")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http201)
        check(response.body == "I super JSON payloard")

    test "PUT endpoint":
        var context = Context(request: Request(HttpMethod.HttpPut, "https://yumad.bro/"))
        var app = App.new()
        app.put("/",
            proc (context: Context) {.async.} =
                context.Created("I am a PUT endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http201)
        check(response.body == "I am a PUT endpoint")

    test "Can GET a endpoint already defined to handle POST requests":
        var context = Context(request: GetRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.post("/memes",
            proc (context: Context) {.async.} =
                context.Created("Create a meme")
        )
        app.get("/memes",
            proc (context: Context) {.async.} =
                context.Ok("Retrieve all the good memes")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "Can POST a endpoint already defined to handle GET requests":
        var context = Context(request: PostRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.get("/memes",
            proc (context: Context) {.async.} =
                context.Ok("Retrieve all the good memes")
        )
        app.post("/memes",
            proc (context: Context) {.async.} =
                context.Created("Create a meme")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http201)

    test "Not found endpoint returns a 404 status code.":
        var context = Context(request: GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a boring home page")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http404)

    test "Wrong HTTP method on a defined endpoint returns a 405 status code.":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a boring home page")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http405)

    test "Can define a nested router":
        var context = Context(request: GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (context: Context) {.async.} =
                context.Ok("Some nice users")
        )

        app.mount("/api/v1", router)

        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)
        check(response.body == "Some nice users")

    test "Cannot define a nested router on a wildcard route":
        var context = Context(request: GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (context: Context) {.async.} =
                context.Ok("Some nice users")
        )

        doAssertRaises(InvalidPathError):
            app.mount("/api/*", router)

    test "Can register a middleware":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()

        app.get("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a boring home page")
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (context: Context) {.async.} =
                if context.request.url.path != "teapot":
                    context.Teapot("")
                    return
                await callback(context)

        app.use(TeapotMiddleware)

        app.compile_routes()

        let response = waitFor app.dispatch(context)
        check(response.status_code == Http418)

    test "Can register a middleware on a sub-router":
        var context = Context(request: GetRequest("https://yumad.bro/users/"))
        var app = App.new()

        var router = Router.new()
        router.get("/",
            proc (context: Context) {.async.} =
                context.Ok("I am a boring home page")
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (context: Context) {.async.} =
                if context.request.url.path != "teapot":
                    context.Teapot("")
                    return
                await callback(context)

        router.use(TeapotMiddleware)
        app.mount("/users", router)

        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http418)


suite "Error handling":
    test "Unhandled exception return an HTTP 500 Bad Request":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
                context.Ok("I am a GET endpoint")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http500)
        check(response.body == "")
