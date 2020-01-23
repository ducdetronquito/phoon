
# Phoon 🐇⚡

A web framework inspired by [ExpressJS](https://expressjs.com/).


[![Build Status](https://api.travis-ci.org/ducdetronquito/phoon.svg?branch=master)](https://travis-ci.org/ducdetronquito/phoon) [![License](https://img.shields.io/badge/license-public%20domain-ff69b4.svg)](https://github.com/ducdetronquito/phoon#license)


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

proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (ctx: Context) {.async.} =
        if ctx.request.headers.hasKey("simple-auth"):
            await callback(ctx)
        else:
            ctx.response.status(Http401)

app.use(SimpleAuthMiddleware)
```


### Error handling

```nim
import phoon

# Define a custom callback that is called when no registered route matched the incoming request path.
app.not_found(
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http404).body("Not Found ¯\\_(ツ)_/¯")
)

# Define a custom callback that is called when an unexpected HTTP method is used on a registered route.
app.method_not_allowed(
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http405).body("Method Not Allowed ¯\\_(ツ)_/¯")
)

# Define a custom callback that is called when unhandled exceptions are raised in your code.
app.bad_request(
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http500).body("Bad Request ¯\\_(ツ)_/¯")
)
```

## License

**Phoon** is released into the **Public Domain**. 🎉🍻
