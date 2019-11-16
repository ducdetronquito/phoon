import asynchttpserver
import ../express/express
import ../express/context
import ../express/routing/router

var app = new App

app.get("/",
    proc (context: Context) =
        context.Response(Http200, "I am a boring home page")
)

app.post("/about",
    proc (context: Context) =
        context.Response(Http201, "What are you talking about ?")
)


var sub_router = Router()

sub_router.get("/users",
    proc (context: Context) =
        context.Response(Http200, "Here are some nice users")
)

app.mount("/nice", sub_router)

app.serve()
