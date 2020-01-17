import phoon

var app = new App

app.get("/",
    proc (context: Context) {.async.} =
        context.response.body = "I am a boring home page"
)

app.post("/about",
    proc (context: Context) {.async.} =
        context.response.status_code = Http201
        context.response.body = "What are you talking about ?"
)

app.get("/ab*",
    proc (context: Context) {.async.} =
        context.response.body = "I am a wildard page !"
)


app.get("/books/{title}",
    proc (context: Context) {.async.} =
        var book_title = context.parameters.get("title")
        context.response.body = "Of course I read '" & book_title & "' !"
)


var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) {.async.} =
        context.response.body = "Here are some nice users"
)

app.mount("/nice", sub_router)


var authenticated_router = Router()

authenticated_router.get("/",
    proc (context: Context) {.async.} =
        context.response.body = "Admins, he is doing it sideways !"
)


proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (context: Context) {.async.} =
        if context.request.headers.hasKey("simple-auth"):
            await callback(context)
        else:
            context.response.status_code = Http401


authenticated_router.use(SimpleAuthMiddleware)
app.mount("/admins", authenticated_router)

app.serve(3000)
