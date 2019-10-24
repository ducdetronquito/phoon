
# Express 🚀🌘

A toy Nim web framework heavily inspired by [ExpressJS](https://expressjs.com/), [Echo](https://github.com/labstack/echo) and [Starlette](https://github.com/encode/starlette).


## Usage

Subject to changes, you know ¯\\_(ツ)_/¯

```nim
import asynchttpserver
import express/express
import express/response

var app = App()

app.get("/",
    proc (request: Request): Response =
        return Ok200("I am a boring home page")
)

app.post("/about",
    proc (request: Request): Response =
        return Created("What are you talking about ?")
)


var router = Router()

router.get("/users",
    proc (request: Request): Response =
            return Ok200("Here are some nice users")
)

app.mount("/nice", router)

app.serve()
```
