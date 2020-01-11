
# Phoon 🐇⚡

An early-stage Nim web framework heavily inspired by [ExpressJS](https://expressjs.com/).


[![Build Status](https://api.travis-ci.org/ducdetronquito/phoon.svg?branch=master)](https://travis-ci.org/ducdetronquito/phoon) [![License](https://img.shields.io/badge/license-public%20domain-ff69b4.svg)](https://github.com/ducdetronquito/phoon#license)


## Usage

Nota Bene: *Phoon is in its early stage, so every of its aspects is subject to changes* 🌪️

### Create an application:

```nim
import asyncdispatch
import asynchttpserver
import phoon

var app = new App

app.get("/",
    proc (context: Context) {.async.} =
        context.Response(Http200, "I am a boring home page")
)

app.post("/users",
    proc (context: Context) {.async.} =
        context.Response(Http201, "You just created a new user !")
)

app.get("/us*",
    proc (context: Context) {.async.} =
        context.Response(Http200, "Every URL starting with 'us' falls back here.")
)

app.get("/books/{title}",
    proc (context: Context) {.async.} =
        var book_title = context.parameters.get("title")
        context.Response(Http200, "Of course I read '" & book_title & "' !")
)

app.serve(8080)
```

### Create a nested router

```nim
import asyncdispatch
import asynchttpserver
import phoon

var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) {.async.} =
        context.Response(Http200, "Here are some nice users")
)

app.mount("/nice", sub_router)
```

### Register a middleware

```nim
import asyncdispatch
import asynchttpserver
import phoon

proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (context: Context)  {.async.} =
        if context.request.headers.hasKey("simple-auth"):
            await callback(context)
        else:
            context.Response(Http401, "")

app.use(SimpleAuthMiddleware)
```


## License

**Phoon** is released into the **Public Domain**. 🎉🍻
