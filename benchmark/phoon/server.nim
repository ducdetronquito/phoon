import asyncdispatch
import asynchttpserver
import src/phoon


var app = new App

app.get("/",
    proc (context: Context) {.async.} =
        context.Ok()
)

app.get("/users/{id}/",
    proc (context: Context) {.async.} =
        let user_id = context.parameters.get("id")
        context.Ok(user_id)
)

app.post("/users/",
    proc (context: Context) {.async.} =
        context.Created(user_id)
)


app.serve()
