import asynchttpserver
import asyncdispatch
import express


var app = App()

app.get("/",
    proc (request: Request) {.async.} =
        await request.respond(Http200, "Sayan Supa Screw! :)")
)

app.serve()
