import src/phoon


var app = new App

app.get("/",
    proc (context: Context) {.async.} =
        discard
)

app.get("/users/{id}/",
    proc (context: Context) {.async.} =
        let user_id = context.parameters.get("id")
        context.response.body = user_id
)

app.post("/users/",
    proc (context: Context) {.async.} =
        context.response.status_code = Http201
        context.response.body = user_id

)


app.serve()
