import asynchttpserver
import asyncdispatch
import express


var app = App()

app.get("/",
    proc (request: Request) {.async.} =
        await request.respond(Http200, "I am a boring home page")
)

app.get("/about",
    proc (request: Request) {.async.} =
        await request.respond(Http200, "What are you talking about ?")
)

app.serve()
