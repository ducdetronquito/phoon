import phoon
import strutils
import unittest
import utils


suite "Endpoints":

    test "DELETE endpoint":
        var ctx = Context.from_request(Request(HttpMethod.HttpDelete, "https://yumad.bro/"))
        var app = App.new()
        app.delete("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)

    test "GET endpoint":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)

    test "HEAD endpoint":
        var ctx = Context.from_request(Request(HttpMethod.HttpHead, "https://yumad.bro/"))
        var app = App.new()
        app.head("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)

    test "OPTIONS endpoint":
        var ctx = Context.from_request(Request(HttpMethod.HttpOptions, "https://yumad.bro/"))
        var app = App.new()
        app.options("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http204)
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http204)

    test "PATCH endpoint":
        var ctx = Context.from_request(Request(HttpMethod.HttpPatch, "https://yumad.bro/"))
        var app = App.new()
        app.patch("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)

    test "POST endpoint":
        var ctx = Context.from_request(PostRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http201)

    test "PUT endpoint":
        var ctx = Context.from_request(Request(HttpMethod.HttpPut, "https://yumad.bro/"))
        var app = App.new()
        app.put("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http201)

    test "Can GET a endpoint already defined to handle POST requests":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.post("/memes",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.get("/memes",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)

    test "Can POST a endpoint already defined to handle GET requests":
        var ctx = Context.from_request(PostRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.get("/memes",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.post("/memes",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http201)


    test "Can chain route definitions":
        var app = App.new()
        app.route("/memes")
            .get(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .post(
                proc (ctx: Context) {.async.} =
                    ctx.response.status(Http201)
            )
        app.compile_routes()

        var ctx = Context.from_request(PostRequest("https://yumad.bro/memes"))
        var response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http201)

        ctx = Context.from_request(GetRequest("https://yumad.bro/memes"))
        response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)


suite "Nested router":
    test "Can define a nested router":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (ctx: Context) {.async.} =
                discard
        )

        app.mount("/api/v1", router)

        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)

    test "Cannot define a nested router on a wildcard route":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (ctx: Context) {.async.} =
                discard
        )

        doAssertRaises(InvalidPathError):
            app.mount("/api/*", router)


suite "Middlewares":
    test "Can register a middleware":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()

        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (ctx: Context) {.async.} =
                if ctx.request.path() != "teapot":
                    ctx.response.status(Http418)
                    return
                await callback(ctx)

        app.use(TeapotMiddleware)

        app.compile_routes()

        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http418)

    test "Can register a middleware on a sub-router":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/users/"))
        var app = App.new()

        var router = Router.new()
        router.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (ctx: Context) {.async.} =
                if ctx.request.path() != "teapot":
                    ctx.response.status(Http418)
                    return
                await callback(ctx)

        router.use(TeapotMiddleware)
        app.mount("/users", router)

        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http418)


suite "Error handling":
    test "Unhandled exception return an HTTP 500 Bad Request":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http500)
        check(response.get_body() == "")

    test "Define a custom HTTP 500 handler":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.bad_request(
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http500).body("¯\\_(ツ)_/¯")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http500)
        check(response.get_body() == "¯\\_(ツ)_/¯")

    test "Fallback to a default Bad Request if the custom HTTP 500 callback fails":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.bad_request(
            proc (ctx: Context) {.async.} =
                discard parseInt("Not a number")
                ctx.response.status(Http500).body("¯\\_(ツ)_/¯")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http500)
        check(response.get_body() == "")

    test "Not found endpoint returns a 404 status code.":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http404)
        check(response.get_body() == "")

    test "Define a custom HTTP 404 handler":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.not_found(
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http404).body("¯\\_(ツ)_/¯")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http404)
        check(response.get_body() == "¯\\_(ツ)_/¯")

    test "Fallback to a custom Bad Request if the custom HTTP 404 callback fails":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.not_found(
            proc (ctx: Context) {.async.} =
                discard parseInt("Not a number")
        )
        app.bad_request(
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http500).body("ᕕ( ᐛ )ᕗ")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http500)
        check(response.get_body() == "ᕕ( ᐛ )ᕗ")

    test "Wrong HTTP method on a defined endpoint returns a 405 status code.":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http405)
        check(response.get_body() == "")

    test "Define a custom HTTP 405 handler":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.method_not_allowed(
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http405).body("¯\\_(ツ)_/¯")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http405)
        check(response.get_body() == "¯\\_(ツ)_/¯")

    test "Fallback to a custom Bad Request if the custom HTTP 405 callback fails":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.method_not_allowed(
            proc (ctx: Context) {.async.} =
                discard parseInt("Not a number")
        )
        app.bad_request(
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http500).body("ᕕ( ᐛ )ᕗ")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http500)
        check(response.get_body() == "ᕕ( ᐛ )ᕗ")


suite "Cookies":

    test "Add a cookie":
        var ctx = Context.from_request(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                ctx.response.cookie("name", "Yay")
        )
        app.compile_routes()
        let response = waitFor app.dispatch(ctx)
        check(response.get_status() == Http200)
        check(response.get_headers()["set-cookie"] == "name=Yay")
