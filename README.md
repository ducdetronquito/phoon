
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
    proc (context: Context) {.async.} =
        context.Ok("I am a boring home page")
)

app.post("/users",
    proc (context: Context) {.async.} =
        context.Created("You just created a new user !")
)

app.get("/us*",
    proc (context: Context) {.async.} =
        context.Ok("Every URL starting with 'us' falls back here.")
)

app.get("/books/{title}",
    proc (context: Context) {.async.} =
        var book_title = context.parameters.get("title")
        context.Ok("Of course I read '" & book_title & "' !")
)

app.serve(8080)
```

### Create a nested router

```nim
import phoon

var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) {.async.} =
        context.Ok("Here are some nice users")
)

app.mount("/nice", sub_router)
```

### Register a middleware

```nim
import phoon

proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (context: Context)  {.async.} =
        if context.request.headers.hasKey("simple-auth"):
            await callback(context)
        else:
            context.Unauthenticated()

app.use(SimpleAuthMiddleware)
```


### Error handling

```nim
import phoon

# Define a custom callback that is called when no registered route matched the incoming request path.
app.not_found(
    proc (context: Context) {.async.} =
        context.NotFound("Not Found ¯\\_(ツ)_/¯")
)

# Define a custom callback that is called when an unexpected HTTP method is used on a registered route.
app.method_not_allowed(
    proc (context: Context) {.async.} =
        context.NotFound("Method Not Allowed ¯\\_(ツ)_/¯")
)

# Define a custom callback that is called when unhandled exceptions are raised in your code.
app.bad_request(
    proc (context: Context) {.async.} =
        context.BadRequest("Bad Request ¯\\_(ツ)_/¯")
)
```

## License

**Phoon** is released into the **Public Domain**. 🎉🍻
