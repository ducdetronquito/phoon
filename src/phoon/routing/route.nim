import asyncdispatch
import asynchttpserver
import ../context/context
import options


type
    Callback* = proc(ctx: Context): Future[void]

    Middleware* = proc (next: Callback): Callback

    Route* = ref object
        onDelete*: Option[Callback]
        onGet*: Option[Callback]
        onHead*: Option[Callback]
        onOptions*: Option[Callback]
        onPatch*: Option[Callback]
        onPost*: Option[Callback]
        onPut*: Option[Callback]


proc delete*(self: Route, callback: Callback): Route {.discardable.} =
    self.onDelete = some(callback)
    return self


proc get*(self: Route, callback: Callback): Route {.discardable.} =
    self.onGet = some(callback)
    return self


proc head*(self: Route, callback: Callback): Route {.discardable.} =
    self.onHead = some(callback)
    return self


proc options*(self: Route, callback: Callback): Route {.discardable.} =
    self.onOptions = some(callback)
    return self


proc patch*(self: Route, callback: Callback): Route {.discardable.} =
    self.onPatch = some(callback)
    return self


proc post*(self: Route, callback: Callback): Route {.discardable.} =
    self.onPost = some(callback)
    return self


proc put*(self: Route, callback: Callback): Route {.discardable.} =
    self.onPut = some(callback)
    return self


proc getCallback*(route: Route, httpMethod: HttpMethod): Option[Callback] =
    case httpMethod
    of HttpMethod.HttpDelete:
        return route.onDelete
    of HttpMethod.HttpGet:
        return route.onGet
    of HttpMethod.HttpHead:
        return route.onHead
    of HttpMethod.HttpOptions:
        return route.onOptions
    of HttpMethod.HttpPatch:
        return route.onPatch
    of HttpMethod.HttpPost:
        return route.onPost
    of HttpMethod.HttpPut:
        return route.onPut
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

    if self.onDelete.isSome:
        let callback = self.onDelete.get().apply(middlewares)
        result.onDelete = some(callback)

    if self.onGet.isSome:
        let callback = self.onGet.get().apply(middlewares)
        result.onGet = some(callback)

    if self.onHead.isSome:
        let callback = self.onHead.get().apply(middlewares)
        result.onHead = some(callback)

    if self.onOptions.isSome:
        let callback = self.onOptions.get().apply(middlewares)
        result.onOptions = some(callback)

    if self.onPatch.isSome:
        let callback = self.onPatch.get().apply(middlewares)
        result.onPatch = some(callback)

    if self.onPost.isSome:
        let callback = self.onPost.get().apply(middlewares)
        result.onPost = some(callback)

    if self.onPut.isSome:
        let callback = self.onPut.get().apply(middlewares)
        result.onPut = some(callback)

    return result
