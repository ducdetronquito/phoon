
# Express 🚀🌘

.. image:: https://img.shields.io/badge/license-public%20domain-ff69b4.svg
    :target: https://github.com/ducdetronquito/express#license

.. image:: https://api.travis-ci.org/ducdetronquito/express.svg?branch=master
     :target: https://travis-ci.org/ducdetronquito/express


A toy Nim web framework heavily inspired by [ExpressJS](https://expressjs.com/), [Echo](https://github.com/labstack/echo) and [Starlette](https://github.com/encode/starlette).


## Usage

Subject to changes, you know ¯\\_(ツ)_/¯

```nim
import asynchttpserver
import express
import express/context
import express/routing/router

var app = new App

app.get("/",
    proc (context: Context) =
        context.Response(Http200, "I am a boring home page")
)

app.post("/about",
    proc (context: Context) =
        context.Response(Http201, "What are you talking about ?")
)


var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) =
        context.Response(Http200, "Here are some nice users")
)

app.mount("/nice", sub_router)

app.serve()
```


License
~~~~~~~

**Express** is released into the **Public Domain**. 🎉🍻
