import phoon
import strutils

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
        var bookTitle = ctx.parameters.get("title")
        ctx.response.body("Of course I read '" & bookTitle & "' !")
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

app.get("/error/",
    proc (ctx: Context) {.async.} =
        discard parseInt("Some business logic that should have been an int")
)


var router = Router()

router.get("/users",
    proc (ctx: Context) {.async.} =
        ctx.response.body("Here are some nice users")
)

app.mount("/nice", router)


var authenticatedRouter = Router()

authenticatedRouter.get("/",
    proc (ctx: Context) {.async.} =
        ctx.response.body("Admins, he is doing it sideways !")
)


proc SimpleAuthMiddleware(next: Callback): Callback =
    return proc (ctx: Context) {.async.} =
        if ctx.request.headers.hasKey("simple-auth"):
            await next(ctx)
        else:
            ctx.response.status(Http401)


authenticatedRouter.use(SimpleAuthMiddleware)
app.mount("/admins", authenticatedRouter)
app.onError(
    proc (ctx: Context, error: ref Exception) {.async.} =
        ctx.response.body(error.msg).status(Http500)
)
app.serve("0.0.0.0", 3000)
