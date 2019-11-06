
# Express 🚀🌘

A toy Nim web framework heavily inspired by [ExpressJS](https://expressjs.com/), [Echo](https://github.com/labstack/echo) and [Starlette](https://github.com/encode/starlette).


## Usage

Subject to changes, you know ¯\\_(ツ)_/¯

```nim
import asynchttpserver
import express/express
import express/context


var app = App()

app.get("/",
    proc (context: Context) =
        context.Response(Http200, "I am a boring home page")
)

app.post("/about",
    proc (context: Context) =
        context.Response(Http201, "What are you talking about ?")
)


var router = Router()

router.get("/users",
    proc (context: Context) =
        context.Response(Http200, "Here are some nice users")
)

app.mount("/nice", router)

app.serve()
```
