import src/phoon


var app = new App

app.get("/",
    proc (ctx: Context) {.async.} =
        discard
)

app.get("/users/{id}/",
    proc (ctx: Context) {.async.} =
        let user_id = ctx.parameters.get("id")
        ctx.response.body(user_id)
)

app.post("/users/",
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http201)
)

app.serve()
