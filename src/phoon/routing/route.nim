import asyncdispatch
import asynchttpserver
import ../context/context
import options


type
    Callback* = proc(ctx: Context): Future[void]

    Middleware* = proc (callback: Callback): Callback

    Route* = ref object
        delete_callback*: Option[Callback]
        get_callback*: Option[Callback]
        head_callback*: Option[Callback]
        options_callback*: Option[Callback]
        patch_callback*: Option[Callback]
        post_callback*: Option[Callback]
        put_callback*: Option[Callback]


proc delete*(self: Route, callback: Callback): Route {.discardable.} =
    self.delete_callback = some(callback)
    return self


proc get*(self: Route, callback: Callback): Route {.discardable.} =
    self.get_callback = some(callback)
    return self


proc head*(self: Route, callback: Callback): Route {.discardable.} =
    self.head_callback = some(callback)
    return self


proc options*(self: Route, callback: Callback): Route {.discardable.} =
    self.options_callback = some(callback)
    return self


proc patch*(self: Route, callback: Callback): Route {.discardable.} =
    self.patch_callback = some(callback)
    return self


proc post*(self: Route, callback: Callback): Route {.discardable.} =
    self.post_callback = some(callback)
    return self


proc put*(self: Route, callback: Callback): Route {.discardable.} =
    self.put_callback = some(callback)
    return self


proc get_callback_of*(route: Route, http_method: HttpMethod): Option[Callback] =
    case http_method
    of HttpMethod.HttpDelete:
        return route.delete_callback
    of HttpMethod.HttpGet:
        return route.get_callback
    of HttpMethod.HttpHead:
        return route.head_callback
    of HttpMethod.HttpOptions:
        return route.options_callback
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

    if self.delete_callback.isSome:
        let callback = self.delete_callback.get().apply(middlewares)
        result.delete_callback = some(callback)

    if self.get_callback.isSome:
        let callback = self.get_callback.get().apply(middlewares)
        result.get_callback = some(callback)

    if self.head_callback.isSome:
        let callback = self.head_callback.get().apply(middlewares)
        result.head_callback = some(callback)

    if self.options_callback.isSome:
        let callback = self.options_callback.get().apply(middlewares)
        result.options_callback = some(callback)

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
