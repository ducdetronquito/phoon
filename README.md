
# Phoon 🐇⚡

A web framework inspired by [ExpressJS](https://expressjs.com/).


![Github Actions](https://github.com/ducdetronquito/phoon/workflows/Github%20Actions/badge.svg) [![License](https://img.shields.io/badge/license-public%20domain-ff69b4.svg)](https://github.com/ducdetronquito/phoon#license)


## Usage

Nota Bene: *Phoon is in its early stage, so every of its aspects is subject to changes* 🌪️

### Create an application:

```nim
import phoon

var app = new App

app.get("/",
    proc (ctx: Context) {.async.} =
        ctx.response.body("I am a boring home page")
)

app.post("/users",
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http201).body("You just created a new user !")
)

app.get("/us*",
    proc (ctx: Context) {.async.} =
        ctx.response.body("Every URL starting with 'us' falls back here.")
)

app.get("/books/{title}",
    proc (ctx: Context) {.async.} =
        # You can retrieve parameters of the URL path
        var book_title = ctx.parameters.get("title")

        # You can also retrieve url-decoded query parameters
        let count = ctx.request.query("count")
        if count.isNone:
            ctx.response.body("Of course I read '" & book_title & "' !")
        else:
            ctx.response.body(
                "Of course I read '" & book_title & "', "
                "at least " & count & " times!"
            )
)

app.get("/cookies/",
    proc (ctx: Context) {.async.} =
        # You can send a cookie along the response
        ctx.response.cookie("size", "A big one 🍪")
)


# Chaining of callbacks for a given path
app.route("/hacks")
    .get(
        proc (ctx: Context) {.async.} =
            ctx.response.body("I handle GET requests")
    )
    .patch(
        proc (ctx: Context) {.async.} =
            ctx.response.body("I handle PATCH requests")
    )
    .delete(
        proc (ctx: Context) {.async.} =
            ctx.response.body("I handle DELETE requests")
    )


app.serve(8080)
```

### Create a nested router

```nim
import phoon

var sub_router = Router()

sub_router.get("/users",
    proc (ctx: Context) {.async.} =
        ctx.response.body("Here are some nice users")
)

app.mount("/nice", sub_router)
```

### Register a middleware

```nim
import phoon

proc SimpleAuthMiddleware(next: Callback): Callback =
    return proc (ctx: Context) {.async.} =
        if ctx.request.headers.hasKey("simple-auth"):
            await next(ctx)
        else:
            ctx.response.status(Http401)

app.use(SimpleAuthMiddleware)
```


### Error handling

```nim
import phoon

# Define a custom callback that is called when no registered route matched the incoming request path.
app.on404(
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http404).body("Not Found ¯\\_(ツ)_/¯")
)

# Define a custom callback that is called when an unhandled exception is raised within your code.
app.onError(
    proc (ctx: Context, error: ref Exception) {.async.} =
        ctx.response.status(Http500).body("Oops ¯\\_(ツ)_/¯\r\n" & error.msg)
)
```

## License

**Phoon** is released under the [BSD Zero clause license](https://choosealicense.com/licenses/0bsd/). 🎉🍻
