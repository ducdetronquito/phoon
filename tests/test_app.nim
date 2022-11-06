import phoon
import strutils
import unittest
import utils


suite "Endpoints":

    test "DELETE endpoint":
        var ctx = Context.new(Request(HttpMethod.HttpDelete, "https://yumad.bro/"))
        var app = App.new()
        app.delete("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)

    test "GET endpoint":
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)

    test "HEAD endpoint":
        var ctx = Context.new(Request(HttpMethod.HttpHead, "https://yumad.bro/"))
        var app = App.new()
        app.head("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)

    test "OPTIONS endpoint":
        var ctx = Context.new(Request(HttpMethod.HttpOptions, "https://yumad.bro/"))
        var app = App.new()
        app.options("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http204)
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http204)

    test "PATCH endpoint":
        var ctx = Context.new(Request(HttpMethod.HttpPatch, "https://yumad.bro/"))
        var app = App.new()
        app.patch("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)

    test "POST endpoint":
        var ctx = Context.new(PostRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http201)

    test "PUT endpoint":
        var ctx = Context.new(Request(HttpMethod.HttpPut, "https://yumad.bro/"))
        var app = App.new()
        app.put("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http201)

    test "Can GET a endpoint already defined to handle POST requests":
        var ctx = Context.new(GetRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.post("/memes",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.get("/memes",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)

    test "Can POST a endpoint already defined to handle GET requests":
        var ctx = Context.new(PostRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.get("/memes",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.post("/memes",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http201)


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
        app.compileRoutes()

        var ctx = Context.new(PostRequest("https://yumad.bro/memes"))
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http201)

        ctx = Context.new(GetRequest("https://yumad.bro/memes"))
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)


suite "Nested router":
    test "Can define a nested router":
        var ctx = Context.new(GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (ctx: Context) {.async.} =
                discard
        )

        app.mount("/api/v1", router)

        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)

    test "Cannot define a nested router on a wildcard route":
        var ctx = Context.new(GetRequest("https://yumad.bro/api/v1/users"))
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
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()

        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )

        proc TeapotMiddleware(next: Callback): Callback =
            return proc (ctx: Context) {.async.} =
                if ctx.request.path() != "teapot":
                    ctx.response.status(Http418)
                    return
                await next(ctx)

        app.use(TeapotMiddleware)

        app.compileRoutes()

        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http418)

    test "Can register a middleware on a sub-router":
        var ctx = Context.new(GetRequest("https://yumad.bro/users/"))
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

        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http418)


suite "Error handling":
    test "Unhandled exception return an HTTP 500 Bad Request":
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http500)
        check(ctx.response.getBody() == "")

    test "Define a custom HTTP 500 handler":
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard parseInt("Some business logic that should have been an int")
        )
        app.onError(
            proc (ctx: Context, error: ref Exception) {.async.} =
                ctx.response.status(Http500).body("¯\\_(ツ)_/¯")
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http500)
        check(ctx.response.getBody() == "¯\\_(ツ)_/¯")

    test "Not found endpoint returns a 404 status code.":
        var ctx = Context.new(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http404)
        check(ctx.response.getBody() == "")

    test "Define a custom HTTP 404 handler":
        var ctx = Context.new(GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                discard
        )
        app.on404(
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http404).body("¯\\_(ツ)_/¯")
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http404)
        check(ctx.response.getBody() == "¯\\_(ツ)_/¯")

    test "Wrong HTTP method on a defined endpoint returns a 405 status code.":
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (ctx: Context) {.async.} =
                ctx.response.status(Http201)
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http405)
        check(ctx.response.getBody() == "")


suite "Cookies":

    test "Add a cookie":
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                ctx.response.cookie("name", "Yay")
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)
        check(ctx.response.getStatus() == Http200)
        check(ctx.response.getHeaders()["set-cookie"] == "name=Yay")

    test "Add multiple cookies":
        var ctx = Context.new(GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (ctx: Context) {.async.} =
                ctx.response.cookie("name", "Yay")
                ctx.response.cookie("surname", "Nay")
        )
        app.compileRoutes()
        waitFor app.dispatch(ctx)

        check(ctx.response.getStatus() == Http200)
        var headers = ctx.response.getHeaders()
        check(headers["set-cookie", 0] == "name=Yay")
        check(headers["set-cookie", 1] == "surname=Nay")
