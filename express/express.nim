import asynchttpserver
import asyncdispatch
import options
import routing/route
import routing/router
import routing/tree
import response


type
    App* = ref object
        router: Router
        routing_table: Tree[Route]


proc new*(app_type: type[App]): App =
    var app = system.new(App)
    app.router = Router.new()
    app.routing_table = Tree[Route].new()
    return app


proc get*(self: var App, path: string, callback: proc (request: Request): Response) =
    self.router.get(path, callback)


proc post*(self: var App, path: string, callback: proc (request: Request): Response) =
    self.router.post(path, callback)


proc mount*(self: var App, path: string, router: Router) =
    self.router.mount(path, router)


proc compile_routes*(self: var App) =
    for path, route in self.router.get_route_pairs():
        self.routing_table.insert(path, route)


proc dispatch*(self: App, request: Request): Response =
    let path = request.url.path

    let potential_route = self.routing_table.retrieve(path)
    if potential_route.isNone:
        return NotFound("")

    let route = potential_route.get()
    let callback = route.get_callback_of(request.reqMethod)

    if callback.isNone:
        return MethodNotAllowed("")

    {.gcsafe.}:
        return callback.get()(request)


proc serve*(self: var App) =

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        let response = self.dispatch(request)
        await request.respond(response.status_code, response.body)

    self.compile_routes()

    let server = newAsyncHttpServer()
    waitFor server.serve(Port(8080), main_dispatch)
