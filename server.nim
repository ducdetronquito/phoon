import asynchttpserver
import asyncdispatch
import express/express


var app = App()

app.get("/",
    proc (request: Request) {.async.} =
        await request.respond(Http200, "I am a boring home page")
)

app.get("/about",
    proc (request: Request) {.async.} =
        await request.respond(Http200, "What are you talking about ?")
)

app.post("/users/",
    proc (request: Request) {.async.} =
        await request.respond(Http201, "Daryl is now a new user")
)

app.get("/users/",
    proc (request: Request) {.async.} =
        await request.respond(Http200, "I know Daryl, Glenn and Michonne")
)

app.serve()
