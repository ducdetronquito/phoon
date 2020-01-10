import asynchttpserver
import asyncdispatch
import phoon/context
import phoon/routing/[errors, route, router, tree]
import options


type
    App* = ref object
        router: Router
        routing_table: Tree[Route]


proc new*(app_type: type[App]): App =
    return App(router: Router(), routing_table: new Tree[Route])


proc get*(self: var App, path: string, callback: Callback) =
    self.router.get(path, callback)


proc post*(self: var App, path: string, callback: Callback) =
    self.router.post(path, callback)


proc put*(self: var App, path: string, callback: Callback) =
    self.router.put(path, callback)


proc mount*(self: var App, path: string, router: Router) =
    self.router.mount(path, router)


proc compile_routes*(self: var App) =
    let middlewares = self.router.get_middlewares()

    for path, route in self.router.get_route_pairs():
        var compile_route = route.apply(middlewares)
        self.routing_table.insert(path, compile_route)


proc dispatch*(self: App, context: Context) {.async, discardable.} =
    let path = context.request.url.path

    let potential_match = self.routing_table.match(path)
    if potential_match.isNone:
        context.Response(Http404, "")
        return

    let match = potential_match.get()
    let route = match.value
    let callback = route.get_callback_of(context.request.reqMethod)
    if callback.isNone:
        context.Response(Http405, "")
        return

    context.parameters = match.parameters
    {.gcsafe.}:
        await callback.get()(context)


proc use*(self: App, middleware: Middleware) =
    self.router.use(middleware)


proc serve*(self: App) =
    var app = deepCopy(self)
    app.compile_routes()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        var context = Context(request: request)
        await app.dispatch(context)
        await request.respond(context.response.status_code, context.response.body)

    let server = newAsyncHttpServer()
    waitFor server.serve(Port(8080), main_dispatch)


export context
export errors
export route
export router
export tree
