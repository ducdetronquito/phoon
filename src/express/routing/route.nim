import asynchttpserver
import express/handler
import options


type
    Route* = ref object
        get_callback*: Option[Callback]
        post_callback*: Option[Callback]


proc get_callback_of*(route: Route, http_method: HttpMethod): Option[Callback] =
    if http_method == HttpMethod.HttpGet:
        return route.get_callback
    elif http_method == HttpMethod.HttpPost:
        return route.post_callback
    else:
        return none(Callback)


proc apply*(self: Route, middlewares: seq[Middleware]): Route =
    result = new Route

    if self.get_callback.isSome:
        let callback = self.get_callback.get().apply(middlewares)
        result.get_callback = some(callback)

    if self.post_callback.isSome:
        let callback = self.post_callback.get().apply(middlewares)
        result.post_callback = some(callback)

    return result
