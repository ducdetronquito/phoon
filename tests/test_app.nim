import asynchttpserver
import express
import unittest
import utils


suite "Endpoints":
    
    test "GET endpoint":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.get("/",
            proc (context: Context) =
                context.Response(Http200, "I am a boring home page")
        )
        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http200)
        check(context.response.body == "I am a boring home page")

    test "POST endpoint":
        var context = Context(request: PostRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) =
                context.Response(Http201, "I super JSON payloard")
        )
        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http201)
        check(context.response.body == "I super JSON payloard")

    test "Can GET a endpoint already defined to handle POST requests":
        var context = Context(request: GetRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.post("/memes",
            proc (context: Context) =
                context.Response(Http201, "Create a meme")
        )
        app.get("/memes",
            proc (context: Context) =
                context.Response(Http200, "Retrieve all the good memes")
        )
        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http200)

    test "Can POST a endpoint already defined to handle GET requests":
        var context = Context(request: PostRequest("https://yumad.bro/memes"))
        var app = App.new()
        app.get("/memes",
            proc (context: Context) =
                context.Response(Http200, "Retrieve all the good memes")
        )
        app.post("/memes",
            proc (context: Context) =
                context.Response(Http201, "Create a meme")
        )
        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http201)

    test "Not found endpoint returns a 404 status code.":
        var context = Context(request: GetRequest("https://yumad.bro/an-undefined-url"))
        var app = App.new()
        app.get("/",
            proc (context: Context) =
                context.Response(Http200, "I am a boring home page")
        )
        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http404)

    test "Wrong HTTP method on a defined endpoint returns a 405 status code.":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()
        app.post("/",
            proc (context: Context) =
                context.Response(Http200, "I am a boring home page")
        )
        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http405)

    test "Can define a nested router":
        var context = Context(request: GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (context: Context) =
                context.Response(Http200, "Some nice users")
        )

        app.mount("/api/v1", router)

        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http200)
        check(context.response.body == "Some nice users")

    test "Cannot define a nested router on a wildcard route":
        var context = Context(request: GetRequest("https://yumad.bro/api/v1/users"))
        var app = App.new()

        var router = Router.new()
        router.get("/users",
            proc (context: Context) =
                context.Response(Http200, "Some nice users")
        )

        doAssertRaises(InvalidPathError):
            app.mount("/api/*", router)

    test "Can register a middleware":
        var context = Context(request: GetRequest("https://yumad.bro/"))
        var app = App.new()

        app.get("/",
            proc (context: Context) =
                context.Response(Http200, "I am a boring home page")
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (context: Context) =
                if context.request.url.path != "teapot":
                    context.Response(Http418, "")
                    return
                callback(context)

        app.use(TeapotMiddleware)

        app.compile_routes()

        app.dispatch(context)
        check(context.response.status_code == Http418)

    test "Can register a middleware on a sub-router":
        var context = Context(request: GetRequest("https://yumad.bro/users/"))
        var app = App.new()

        var router = Router.new()
        router.get("/",
            proc (context: Context) =
                context.Response(Http200, "I am a boring home page")
        )

        proc TeapotMiddleware(callback: Callback): Callback =
            return proc (context: Context) =
                if context.request.url.path != "teapot":
                    context.Response(Http418, "")
                    return
                callback(context)

        router.use(TeapotMiddleware)
        app.mount("/users", router)

        app.compile_routes()
        app.dispatch(context)
        check(context.response.status_code == Http418)
