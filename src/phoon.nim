import asynchttpserver
import asyncdispatch
import phoon/context
import phoon/routing/[errors, route, router, tree]
import options


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


proc head*(self: var App, path: string, callback: Callback) =
    self.router.head(path, callback)


proc delete*(self: var App, path: string, callback: Callback) =
    self.router.delete(path, callback)


proc get*(self: var App, path: string, callback: Callback) =
    self.router.get(path, callback)


proc options*(self: var App, path: string, callback: Callback) =
    self.router.options(path, callback)


proc patch*(self: var App, path: string, callback: Callback) =
    self.router.patch(path, callback)


proc post*(self: var App, path: string, callback: Callback) =
    self.router.post(path, callback)


proc put*(self: var App, path: string, callback: Callback) =
    self.router.put(path, callback)


proc mount*(self: var App, path: string, router: Router) =
    self.router.mount(path, router)


proc bad_request*(self: var App, callback: Callback) =
    self.bad_request_callback = callback


proc not_found*(self: var App, callback: Callback) =
    self.not_found_callback = callback


proc method_not_allowed*(self: var App, callback: Callback) =
    self.method_not_allowed_callback = callback


proc compile_routes*(self: var App) =
    let middlewares = self.router.get_middlewares()

    for path, route in self.router.get_route_pairs():
        var compile_route = route.apply(middlewares)
        self.routing_table.insert(path, compile_route)


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
    let path = ctx.request.url.path

    let potential_match = self.routing_table.match(path)
    if potential_match.isNone:
        {.gcsafe.}:
            let response = await fail_safe(self, self.not_found_callback, ctx)
            return response

    let match = potential_match.get()
    let route = match.value
    let callback = route.get_callback_of(ctx.request.reqMethod)
    if callback.isNone:
        {.gcsafe.}:
            let response = await fail_safe(self, self.method_not_allowed_callback, ctx)
            return response

    ctx.parameters = match.parameters
    {.gcsafe.}:
        let response = await fail_safe(self, callback.get(), ctx)
        return response


proc use*(self: App, middleware: Middleware) =
    self.router.use(middleware)


proc serve*(self: App, port: int, address: string = "") =
    var app = deepCopy(self)
    app.compile_routes()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        var ctx = Context.from_request(request)
        let response = await app.dispatch(ctx)
        await request.respond(response.get_status(), response.get_body(), response.headers)

    let server = newAsyncHttpServer()
    waitFor server.serve(port = Port(port), callback = main_dispatch, address = address)


proc serve*(self: App) =
    self.serve(8080)

export asynchttpserver
export asyncdispatch
export context
export errors
export route
export router
export tree
