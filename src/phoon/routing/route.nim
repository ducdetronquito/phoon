import asyncdispatch
import asynchttpserver
import ../context
import options


type
    Callback* = proc(context: Context): Future[void]

    Middleware* = proc (callback: Callback): Callback

    Route* = ref object
        get_callback*: Option[Callback]
        patch_callback*: Option[Callback]
        post_callback*: Option[Callback]
        put_callback*: Option[Callback]


proc get_callback_of*(route: Route, http_method: HttpMethod): Option[Callback] =
    case http_method
    of HttpMethod.HttpGet:
        return route.get_callback
    of HttpMethod.HttpPatch:
        return route.patch_callback
    of HttpMethod.HttpPost:
        return route.post_callback
    of HttpMethod.HttpPut:
        return route.put_callback
    else:
        return none(Callback)


proc apply*(self: Callback, middlewares: seq[Middleware]): Callback =
    if middlewares.len() == 0:
        return self

    result = self
    for middleware in middlewares:
        result = middleware(result)

    return result


proc apply*(self: Route, middlewares: seq[Middleware]): Route =
    result = new Route

    if self.get_callback.isSome:
        let callback = self.get_callback.get().apply(middlewares)
        result.get_callback = some(callback)

    if self.patch_callback.isSome:
        let callback = self.patch_callback.get().apply(middlewares)
        result.patch_callback = some(callback)

    if self.post_callback.isSome:
        let callback = self.post_callback.get().apply(middlewares)
        result.post_callback = some(callback)

    if self.put_callback.isSome:
        let callback = self.put_callback.get().apply(middlewares)
        result.put_callback = some(callback)

    return result
