import asynchttpserver
import options
import ../response


type
    Callback* = proc(request: Request): Response


type
    Route* = object
        path*: string
        callback*: Callback
        get_callback*: Option[Callback]
        post_callback*: Option[Callback]


proc get_callback_of*(route: Route, http_method: HttpMethod): Option[Callback] =
    if http_method == HttpMethod.HttpGet:
        return route.get_callback
    elif http_method == HttpMethod.HttpPost:
        return route.post_callback
    else:
        return none(Callback)
