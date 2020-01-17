import phoon
import strutils
import unittest
import utils


suite "Endpoints":

    test "DELETE endpoint":
        var context = Context.from_request(Request(HttpMethod.HttpDelete, "https://yumad.bro/"))
        var app = App.new()
        app.delete("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "GET endpoint":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "HEAD endpoint":
        var context = Context.from_request(Request(HttpMethod.HttpHead, "https://yumad.bro/"))
        var app = App.new()
        app.head("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "OPTIONS endpoint":
        var context = Context.from_request(Request(HttpMethod.HttpOptions, "https://yumad.bro/"))
        var app = App.new()
        app.options("/",
            proc (context: Context) {.async.} =
                context.response.status_code = Http204
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http204)

    test "PATCH endpoint":
        var context = Context.from_request(Request(HttpMethod.HttpPatch, "https://yumad.bro/"))
        var app = App.new()
        app.patch("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "POST endpoint":
        var context = Context.from_request(PostRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http201)

    test "PUT endpoint":
        var context = Context.from_request(Request(HttpMethod.HttpPut, "https://yumad.bro/"))
        var app = App.new()
        app.put("/",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http201)

    test "Can GET a endpoint already defined to handle POST requests":
        var context = Context.from_request(GetRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.post("/memes",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.get("/memes",
            proc (context: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "Can POST a endpoint already defined to handle GET requests":
        var context = Context.from_request(PostRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.get("/memes",
            proc (context: Context) {.async.} =
                discard
        )
        app.post("/memes",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http201)

    test "Can define a nested router":
        var context = Context.from_request(GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (context: Context) {.async.} =
                discard
        )

        app.mount("/api/v1", router)

        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http200)

    test "Cannot define a nested router on a wildcard route":
        var context = Context.from_request(GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (context: Context) {.async.} =
                discard
        )

        doAssertRaises(InvalidPathError):
            app.mount("/api/*", router)

    test "Can register a middleware":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()

        app.get("/",
            proc (context: Context) {.async.} =
                discard
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (context: Context) {.async.} =
                if context.request.url.path != "teapot":
                    context.response.status_code = Http418
                    return
                await callback(context)

        app.use(TeapotMiddleware)

        app.compile_routes()

        let response = waitFor app.dispatch(context)
        check(response.status_code == Http418)

    test "Can register a middleware on a sub-router":
        var context = Context.from_request(GetRequest("https://yumad.bro/users/"))
        var app = App.new()

        var router = Router.new()
        router.get("/",
            proc (context: Context) {.async.} =
                discard
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (context: Context) {.async.} =
                if context.request.url.path != "teapot":
                    context.response.status_code = Http418
                    return
                await callback(context)

        router.use(TeapotMiddleware)
        app.mount("/users", router)

        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http418)


suite "Error handling":
    test "Unhandled exception return an HTTP 500 Bad Request":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http500)
        check(response.body == "")

    test "Define a custom HTTP 500 handler":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.bad_request(
            proc (context: Context) {.async.} =
                context.response.status_code = Http500
                context.response.body = "¯\\_(ツ)_/¯"
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http500)
        check(response.body == "¯\\_(ツ)_/¯")

    test "Fallback to a default Bad Request if the custom HTTP 500 callback fails":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.bad_request(
            proc (context: Context) {.async.} =
                discard parseInt("Not a number")
                context.response.status_code = Http500
                context.response.body = "¯\\_(ツ)_/¯"
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http500)
        check(response.body == "")

    test "Not found endpoint returns a 404 status code.":
        var context = Context.from_request(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http404)
        check(response.body == "")

    test "Define a custom HTTP 404 handler":
        var context = Context.from_request(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.not_found(
            proc (context: Context) {.async.} =
                context.response.status_code = Http404
                context.response.body = "¯\\_(ツ)_/¯"
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http404)
        check(response.body == "¯\\_(ツ)_/¯")

    test "Fallback to a custom Bad Request if the custom HTTP 404 callback fails":
        var context = Context.from_request(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (context: Context) {.async.} =
                discard
        )
        app.not_found(
            proc (context: Context) {.async.} =
                discard parseInt("Not a number")
        )
        app.bad_request(
            proc (context: Context) {.async.} =
                context.response.status_code = Http500
                context.response.body = "ᕕ( ᐛ )ᕗ"
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http500)
        check(response.body == "ᕕ( ᐛ )ᕗ")

    test "Wrong HTTP method on a defined endpoint returns a 405 status code.":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http405)
        check(response.body == "")

    test "Define a custom HTTP 405 handler":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.method_not_allowed(
            proc (context: Context) {.async.} =
                context.response.status_code = Http405
                context.response.body = "¯\\_(ツ)_/¯"
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http405)
        check(response.body == "¯\\_(ツ)_/¯")

    test "Fallback to a custom Bad Request if the custom HTTP 405 callback fails":
        var context = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) {.async.} =
                context.response.status_code = Http201
        )
        app.method_not_allowed(
            proc (context: Context) {.async.} =
                discard parseInt("Not a number")
        )
        app.bad_request(
            proc (context: Context) {.async.} =
                context.response.status_code = Http500
                context.response.body = "ᕕ( ᐛ )ᕗ"
        )
        app.compile_routes()
        let response = waitFor app.dispatch(context)
        check(response.status_code == Http500)
        check(response.body == "ᕕ( ᐛ )ᕗ")
