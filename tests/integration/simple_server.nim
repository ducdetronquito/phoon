import phoon

var app = new App

app.get("/",
    proc (ctx: Context) {.async.} =
        ctx.response.body("I am a boring home page")
)

app.post("/about",
    proc (ctx: Context) {.async.} =
        ctx.response.status(Http201).body("What are you talking about ?")
)

app.get("/ab*",
    proc (ctx: Context) {.async.} =
        ctx.response.body("I am a wildard page !")
)


app.get("/books/{title}",
    proc (ctx: Context) {.async.} =
        var book_title = ctx.parameters.get("title")
        ctx.response.body("Of course I read '" & book_title & "' !")
)

app.get("/json",
    proc (ctx: Context) {.async.} =
        ctx.response.headers("Content-Type", "application/json")
        ctx.response.body("{}")
)

app.get("/query_parameters/",
    proc (ctx: Context) {.async.} =
        let name = ctx.request.query("name").get()
        ctx.response.body(name)
)


app.get("/cookies/",
    proc (ctx: Context) {.async.} =
        ctx.response.cookie("name", "Yay")
)


var sub_router = Router()

sub_router.get("/users",
    proc (ctx: Context) {.async.} =
        ctx.response.body("Here are some nice users")
)

app.mount("/nice", sub_router)


var authenticated_router = Router()

authenticated_router.get("/",
    proc (ctx: Context) {.async.} =
        ctx.response.body("Admins, he is doing it sideways !")
)


proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (ctx: Context) {.async.} =
        if ctx.request.headers.hasKey("simple-auth"):
            await callback(ctx)
        else:
            ctx.response.status(Http401)


authenticated_router.use(SimpleAuthMiddleware)
app.mount("/admins", authenticated_router)

app.serve(3000)
