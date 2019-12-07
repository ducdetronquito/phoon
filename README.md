
# Express 🚀🌘

A toy Nim web framework heavily inspired by [ExpressJS](https://expressjs.com/), [Echo](https://github.com/labstack/echo) and [Starlette](https://github.com/encode/starlette).


[![Build Status](https://api.travis-ci.org/ducdetronquito/express.svg?branch=master)](https://travis-ci.org/ducdetronquito/express) [![License](https://img.shields.io/badge/license-public%20domain-ff69b4.svg)](https://github.com/ducdetronquito/express#license)


## Usage

Nota Bene: *Express is in its early stage, so every of its aspects is subject to changes* 🌪️

### Create an application:

```nim
import asynchttpserver
import express

var app = new App

app.get("/",
    proc (context: Context) =
        context.Response(Http200, "I am a boring home page")
)

app.post("/users",
    proc (context: Context) =
        context.Response(Http201, "You just created a new user !")
)

app.get("/us*",
    proc (context: Context) =
        context.Response(Http200, "Every URL starting with 'us' falls back here.")
)

app.get("/books/{title}",
    proc (context: Context) =
        var book_title = context.parameters.get("title")
        context.Response(Http200, "Of course I read '" & book_title & "' !")
)

app.serve()
```

### Create a nested router

```nim
import asynchttpserver
import express

var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) =
        context.Response(Http200, "Here are some nice users")
)

app.mount("/nice", sub_router)
```

### Register a middleware

```nim
import asynchttpserver
import express

proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (context: Context) =
        if context.request.headers.hasKey("simple-auth"):
            callback(context)
        else:
            context.Response(Http401, "")

app.use(SimpleAuthMiddleware)
```


## License

**Express** is released into the **Public Domain**. 🎉🍻
