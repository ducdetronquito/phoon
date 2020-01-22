from asynchttpserver import nil
import asyncdispatch
import httpcore
import options
import phoon/context/[context, request, response]
import phoon/routing/[errors, route, router, tree]


type
    App* = ref object
        router: Router
        routing_table: Tree[Route]
        bad_request_callback*: Callback
        not_found_callback*: Callback
        method_not_allowed_callback*: Callback

proc default_bad_request_callback(ctx: Context) {.async.} =
    ctx.response.status(Http500)


proc default_not_found_callback(ctx: Context) {.async.} =
    ctx.response.status(Http404)


proc default_method_not_allowed_callback(ctx: Context) {.async.} =
    ctx.response.status(Http405)


proc new*(app_type: type[App]): App =
    return App(
        router: Router(),
        routing_table: new Tree[Route],
        bad_request_callback: default_bad_request_callback,
        not_found_callback: default_not_found_callback,
        method_not_allowed_callback: default_method_not_allowed_callback
    )


proc head*(self: App, path: string, callback: Callback) =
    self.router.head(path, callback)


proc delete*(self: App, path: string, callback: Callback) =
    self.router.delete(path, callback)


proc get*(self: App, path: string, callback: Callback) =
    self.router.get(path, callback)


proc options*(self: App, path: string, callback: Callback) =
    self.router.options(path, callback)


proc patch*(self: App, path: string, callback: Callback) =
    self.router.patch(path, callback)


proc post*(self: App, path: string, callback: Callback) =
    self.router.post(path, callback)


proc put*(self: App, path: string, callback: Callback) =
    self.router.put(path, callback)


proc route*(self: App, path: string): Route {.discardable.} =
    return self.router.route(path)


proc mount*(self: App, path: string, router: Router) =
    self.router.mount(path, router)


proc use*(self: App, middleware: Middleware) =
    self.router.use(middleware)


proc bad_request*(self: App, callback: Callback) =
    self.bad_request_callback = callback


proc not_found*(self: App, callback: Callback) =
    self.not_found_callback = callback


proc method_not_allowed*(self: App, callback: Callback) =
    self.method_not_allowed_callback = callback


proc compile_routes*(self: App) =
    let middlewares = self.router.get_middlewares()

    for path, route in self.router.get_route_pairs():
        var compiled_route = route.apply(middlewares)
        self.routing_table.insert(path, compiled_route)


proc fail_safe(self: App, callback: Callback, ctx: Context): Future[Response] {.async.} =
    let callback_future = callback(ctx)
    yield callback_future
    if not callback_future.failed:
        return ctx.response

    ctx.response = Response.new()

    let bad_request_future = self.bad_request_callback(ctx)
    yield bad_request_future
    if not bad_request_future.failed:
        return ctx.response

    await default_bad_request_callback(ctx)
    return ctx.response


proc dispatch*(self: App, ctx: Context): Future[Response] {.async.} =
    let potential_match = self.routing_table.match(ctx.request.path())
    if potential_match.isNone:
        {.gcsafe.}:
            let response = await fail_safe(self, self.not_found_callback, ctx)
            return response.compile()

    let match = potential_match.get()
    let route = match.value
    let callback = route.get_callback_of(ctx.request.http_method())
    if callback.isNone:
        {.gcsafe.}:
            let response = await fail_safe(self, self.method_not_allowed_callback, ctx)
            return response.compile()

    ctx.parameters = match.parameters
    {.gcsafe.}:
        let response = await fail_safe(self, callback.get(), ctx)
        return response.compile()


proc serve*(self: App, port: int, address: string = "") =
    var app = deepCopy(self)
    app.compile_routes()

    proc main_dispatch(request: asynchttpserver.Request) {.async, gcsafe.} =
        var ctx = Context.from_request(request)
        let response = await app.dispatch(ctx)
        await asynchttpserver.respond(request, response.get_status(), response.get_body(), response.get_headers())

    let server = asynchttpserver.newAsyncHttpServer()
    waitFor asynchttpserver.serve(server, port = Port(port), callback = main_dispatch, address = address)


proc serve*(self: App) =
    self.serve(8080)


export asyncdispatch
export context
export errors
export httpcore
export request
export response except compile
export route
export router
export tree
