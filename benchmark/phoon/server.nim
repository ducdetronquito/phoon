import asyncdispatch
import asynchttpserver
import src/phoon


var app = new App

app.get("/",
    proc (context: Context) {.async.} =
        context.Response(Http200, "")
)

app.get("/users/{id}/",
    proc (context: Context) {.async.} =
        let user_id = context.parameters.get("id")
        context.Response(Http200, user_id)
)

app.post("/users/",
    proc (context: Context) {.async.} =
        context.Response(Http201, "")
)


app.serve()
