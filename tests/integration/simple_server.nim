import asynchttpserver
import express
import express/handler
import express/context
import express/routing/router
import tables

var app = new App

app.get("/",
    proc (context: Context) =
        context.Response(Http200, "I am a boring home page")
)

app.post("/about",
    proc (context: Context) =
        context.Response(Http201, "What are you talking about ?")
)

app.get("/ab*",
    proc (context: Context) =
        context.Response(Http200, "I am a wildard page !")
)


app.get("/books/{title}",
    proc (context: Context) =
        var book_title = context.parameters["title"]
        context.Response(Http200, "Of course I read '" & book_title & "' !")
)


var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) =
        context.Response(Http200, "Here are some nice users")
)

app.mount("/nice", sub_router)


var authenticated_router = Router()

authenticated_router.get("/",
    proc (context: Context) =
        context.Response(Http200, "Admins, he is doing it sideways !")
)


proc SimpleAuthMiddleware(callback: Callback): Callback =
    return proc (context: Context) =
        if context.request.headers.hasKey("simple-auth"):
            callback(context)
        else:
            context.Response(Http401, "")


authenticated_router.use(SimpleAuthMiddleware)
app.mount("/admins", authenticated_router)

app.serve()
