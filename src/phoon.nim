from asynchttpserver import nil
import asyncdispatch except Callback
import httpcore
import options
import phoon/context/[context, request, response]
import phoon/routing/[errors, route, router, tree]


type
    ErrorCallback = proc(ctx: Context, error: ref Exception): Future[void]

    App* = ref object
        router: Router
        routingTable: Tree[Route]
        errorCallback: ErrorCallback
        routeNotFound: Callback


proc defaultErrorCallback(ctx: Context, error: ref Exception) {.async.} =
    ctx.response.status(Http500)


proc default404callback(ctx: Context) {.async.} =
    ctx.response.status(Http404)


proc new*(app_type: type[App]): App =
    return App(
        router: Router(),
        routingTable: new Tree[Route],
        errorCallback: defaultErrorCallback,
        routeNotFound: default404callback,
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


proc onError*(self: App, callback: ErrorCallback) =
    self.errorCallback = callback


proc on404*(self: App, callback: Callback) =
    self.routeNotFound = callback


proc compileRoutes*(self: App) =
    let middlewares = self.router.get_middlewares()

    for path, route in self.router.get_route_pairs():
        var compiledRoute = route.apply(middlewares)
        self.routingTable.insert(path, compiledRoute)


proc unsafeDispatch(self: App, ctx: Context) {.async.} =
    let match = self.routingTable.match(ctx.request.path())
    if match.isNone:
        await self.routeNotFound(ctx)
        return

    let (route, parameters)  = match.unsafeGet()
    let callback = route.getCallback(ctx.request.httpMethod())
    if callback.isNone:
        ctx.response.status(Http405)
        return

    ctx.parameters = parameters
    await callback.unsafeGet()(ctx)
    return


proc dispatch*(self: App, ctx: Context) {.async.} =
    try:
        await self.unsafeDispatch(ctx)
    except Exception as error:
        await self.errorCallback(ctx, error)


proc serve*(self: App, port: int, address: string = "") =
    self.compileRoutes()

    proc dispatch(request: asynchttpserver.Request) {.async.} =
        var ctx = Context.from_request(request)
        {.gcsafe.}:
            await self.dispatch(ctx)
        let response = ctx.response
        await asynchttpserver.respond(request, response.get_status(), response.get_body(), response.get_headers())

    let server = asynchttpserver.newAsyncHttpServer()
    waitFor asynchttpserver.serve(server, port = Port(port), callback = dispatch, address = address)


proc serve*(self: App) =
    self.serve(8080)


export asyncdispatch except Callback
export context
export errors
export httpcore
export request
export response except compile
export route
export router
export tree
