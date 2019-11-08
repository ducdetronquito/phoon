import asynchttpserver
import asyncdispatch
import context
import handler
import options
import routing/route
import routing/router
import routing/tree


type
    App* = ref object
        router: Router
        routing_table: Tree[Route]


proc new*(app_type: type[App]): App =
    var app = system.new(App)
    app.router = Router.new()
    app.routing_table = Tree[Route].new()
    return app


proc get*(self: var App, path: string, callback: Callback) =
    self.router.get(path, callback)


proc post*(self: var App, path: string, callback: Callback) =
    self.router.post(path, callback)


proc mount*(self: var App, path: string, router: Router) =
    self.router.mount(path, router)


proc compile_routes*(self: var App) =
    let middlewares = self.router.get_middlewares()

    for path, route in self.router.get_route_pairs():
        var compile_route = new Route
        if route.get_callback.isSome:
            let callback = route.get_callback.get().apply(middlewares)
            compile_route.get_callback = some(callback)

        if route.post_callback.isSome:
            let callback =route.post_callback.get().apply(middlewares)
            compile_route.post_callback = some(callback)

        self.routing_table.insert(path, compile_route)


proc dispatch*(self: App, context: Context) =
    let path = context.request.url.path

    let potential_route = self.routing_table.retrieve(path)
    if potential_route.isNone:
        context.Response(Http404, "")
        return

    let route = potential_route.get()
    let callback = route.get_callback_of(context.request.reqMethod)

    if callback.isNone:
        context.Response(Http405, "")
        return

    {.gcsafe.}:
        callback.get()(context)


proc use*(self: App, middleware: Middleware) =
    self.router.use(middleware)


proc serve*(self: var App) =

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        var context = new Context
        context.request = request
        self.dispatch(context)
        await request.respond(context.response.status_code, context.response.body)

    self.compile_routes()

    let server = newAsyncHttpServer()
    waitFor server.serve(Port(8080), main_dispatch)
